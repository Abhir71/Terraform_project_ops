# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.environment}-rds"
  
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class
  
  allocated_storage     = var.allocated_storage
  storage_encrypted     = true
  storage_type          = "gp3"
  
  db_name  = var.db_name
  username = var.username
  password = var.password
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = var.deletion_protection
  
  parameter_group_name = aws_db_parameter_group.main.name
  
  tags = {
    Environment = var.environment
  }
}

# Subnet Group
resource "aws_db_subnet_group" "main" {
  name        = "${var.environment}-db-subnet-group"
  description = "RDS subnet group for ${var.environment}"
  subnet_ids  = var.private_subnet_ids
  
  tags = {
    Environment = var.environment
  }
}

# Security Group
resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow from ECS"
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
  }
}

# Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = "${var.environment}-pg"
  family = var.parameter_group_family

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = {
    Environment = var.environment
  }
}

# Secret for password
resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.environment}-rds-password-new-secret"
  
  tags = {
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.password
}