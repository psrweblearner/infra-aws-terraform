/*
IMPORTANT:
- Outputs expose key connection points after apply:
  EC2 identity, public IP, S3 bucket, and RDS endpoint/port.

NOT IMPORTANT:
- Outputs do not create resources; they are for visibility and integration convenience.
*/
output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app_server.id
}

output "elastic_ip" {
  description = "Elastic IP attached to EC2"
  value       = aws_eip.app_eip.public_ip
}

output "s3_bucket_name" {
  description = "Application S3 bucket name"
  value       = aws_s3_bucket.app_bucket.bucket
}

output "rds_endpoint" {
  description = "RDS endpoint (private)"
  value       = aws_db_instance.app_db.address
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.app_db.port
}
