aws_region  = "ap-south-1"
environment = "dev"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

ecs_task_cpu      = 256
ecs_task_memory   = 512
ecs_desired_count = 1

rds_instance_class      = "db.t3.micro"
rds_allocated_storage   = 20
rds_backup_retention    = 7
rds_deletion_protection = false
rds_skip_final_snapshot = true

log_retention_days = 14