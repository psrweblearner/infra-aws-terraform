output "elastic_ip" {
  description = "Public Elastic IP for EC2 (use this for DNS A record)"
  value       = aws_eip.app.public_ip
}

output "app_endpoint" {
  description = "Use domain if configured, otherwise use Elastic IP"
  value       = var.api_domain_name != "" ? var.api_domain_name : aws_eip.app.public_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "rds_endpoint" {
  description = "Private MySQL endpoint"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "MySQL port"
  value       = aws_db_instance.mysql.port
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.starterkit.bucket
}
