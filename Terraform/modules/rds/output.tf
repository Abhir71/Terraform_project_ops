output "rds_id" {
  value = aws_db_instance.main.id
}

output "rds_address" {
  value = aws_db_instance.main.address
}

output "rds_port" {
  value = aws_db_instance.main.port
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}

output "password_secret_arn" {
  value = aws_secretsmanager_secret.db_password.arn
}