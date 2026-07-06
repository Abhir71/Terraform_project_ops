Repo layout

devops-assessment/
├── terraform/
│   ├── modules/
│   │   ├── network/   
│   │   ├── ecs/       
│   │   └── rds/       
│   └── envs/
│       ├── dev/       
│       └── prod/      
├── docker/
│   ├── docker-compose.yml
│   ├── migrations/001_initial_schema.sql   
│   └── seed/seed_data.sql                  
├── scripts/
│   ├── backup.sh     
│   └── restore.sh     
└── .github/workflows/terraform.yml 


RDS is never public: publicly_accessible = false; security group only
allows inbound from the ECS security group.
ECS only accepts traffic from the ALB security group.
ALB/ECS/RDS security groups are created at the env level, not inside
the ecs module — this avoids an ecs → rds → ecs module cycle (rds
needs the ECS SG id, ecs needs the RDS endpoint)


What was actually tested


Terraform: hand-reviewed (module wiring, SG scoping, cycle avoidance) —
no Terraform binary available in the authoring environment; run the
fmt/init/validate/plan commands above as the first sanity check.
Database: tested end-to-end locally — migration + seed run clean, target
query returns correct results, EXPLAIN ANALYZE confirms the index plan,
and a full pg_dump → pg_restore cycle matched row counts exactly.


Known simplifications


db_master_password is a plain Terraform variable for plan-only review;
production should pull it from Secrets Manager / SSM.
ECS task uses a placeholder image (nginx:latest) instead of a built/pushed app image.
terraform.tfvars files are committed here for reviewer convenience only.