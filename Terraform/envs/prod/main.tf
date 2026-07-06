terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


module "network" {
  source = "../.../modules/network"
  
  environment = var.environment
  vpc_cidr   = var.vpc_cidr
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}


resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.network.vpc_id
  
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
  }
}

resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = module.network.public_subnet_ids
  
  # Enable deletion protection for prod....
  enable_deletion_protection = true
  
  tags = {
    Name        = "${var.environment}-alb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.environment}-app-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = module.network.vpc_id
  target_type = "ip"
  
  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout            = 10
    interval           = 30
    path               = "/"
    matcher            = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  # PROD: Redirect HTTP to HTTPS
  default_action {
    type = "redirect"
    
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}


module "rds" {
  source = "../.../modules/rds"
  
  environment = var.environment
  vpc_id     = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  ecs_security_group_id = module.ecs.ecs_security_group_id
  
  engine           = var.rds_engine
  engine_version   = var.rds_engine_version
  instance_class   = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  
  db_name     = var.rds_db_name
  username    = var.rds_username
  password    = var.rds_password
  
  # PROD: Longer backup retention
  backup_retention_period = var.rds_backup_retention
  skip_final_snapshot    = var.rds_skip_final_snapshot
  deletion_protection    = var.rds_deletion_protection
  
  parameter_group_family = var.rds_parameter_group_family
  port                  = var.rds_port
}


module "ecs" {
  source = "../.../modules/ecs"
  
  environment = var.environment
  vpc_id     = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  
  container_image = var.container_image
  container_port  = var.container_port
  

  task_cpu     = var.ecs_task_cpu
  task_memory  = var.ecs_task_memory
  desired_count = var.ecs_desired_count
  
  rds_host = module.rds.rds_address
  rds_db_name = var.rds_db_name
  rds_username = var.rds_username
  rds_password_secret_arn = module.rds.password_secret_arn
  
  aws_region = var.aws_region
  
  alb_security_group_id = aws_security_group.alb.id
  target_group_arn     = aws_lb_target_group.app.arn
  alb_listener_arn     = aws_lb_listener.https.arn
  

  log_retention_days = var.log_retention_days
}


# CloudWatch Alarms for PROD
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.environment}-rds-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/RDS"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "RDS CPU utilization is too high"
  alarm_actions      = [var.sns_topic_arn]
  
  dimensions = {
    DBInstanceIdentifier = module.rds.rds_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${var.environment}-rds-free-storage-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "FreeStorageSpace"
  namespace          = "AWS/RDS"
  period             = "300"
  statistic          = "Average"
  threshold          = "5000000000"
  alarm_description  = "RDS free storage is too low"
  alarm_actions      = [var.sns_topic_arn]
  
  dimensions = {
    DBInstanceIdentifier = module.rds.rds_id
  }
}


resource "aws_wafv2_web_acl" "main" {
  name        = "${var.environment}-waf"
  description = "WAF for ${var.environment}"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "${var.environment}-waf"
    sampled_requests_enabled  = true
  }
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}


output "alb_dns_name" {
  value = aws_lb.main.dns_name
  description = "The DNS name of the ALB"
}

output "rds_address" {
  value = module.rds.rds_address
  description = "The RDS instance address"
  sensitive = true
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
  description = "The ECS cluster name"
}