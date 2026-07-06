# AWS Configuration
aws_region = "ap-south-1"
environment = "prod"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
availability_zones = ["ap-south-1a", "ap-south-1b"]


ecs_task_cpu = 512
ecs_task_memory = 1024
ecs_desired_count = 2


rds_instance_class = "db.t3.medium"
rds_allocated_storage = 100
rds_backup_retention = 30
rds_deletion_protection = true
rds_skip_final_snapshot = false


log_retention_days = 30


certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/your-certificate-id"


sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:prod-alarms"