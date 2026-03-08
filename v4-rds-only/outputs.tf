output "rds_endpoint" {
  description = "Public MySQL endpoint"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "MySQL port"
  value       = aws_db_instance.mysql.port
}

output "rds_connection_string" {
  description = "MySQL connection string"
  value       = "mysql://${var.db_username}:${var.db_password}@${aws_db_instance.mysql.address}:${aws_db_instance.mysql.port}/${var.db_name}"
  sensitive   = true
}

output "allowed_mysql_cidrs" {
  description = "CIDR blocks currently allowed to reach MySQL"
  value       = var.allowed_mysql_cidrs
}
