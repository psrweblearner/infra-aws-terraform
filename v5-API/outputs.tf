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

output "ssh_private_key" {
  description = "The generated private key for SSH access. SAVE THIS TO A FILE (e.g., id_rsa) AND CHMOD 400."
  value       = tls_private_key.main.private_key_pem
  sensitive   = true
}

output "deployment_instructions" {
  description = "Steps to finalize deployment"
  value       = <<EOF
1. Point your Cloudflare DNS (A Record) for ${var.domain_name} to ${aws_eip.app_eip.public_ip}.
2. Save the 'ssh_private_key' output to a file named 'id_rsa' and run 'chmod 400 id_rsa'.
3. SSH into the instance: ssh -i id_rsa ubuntu@${aws_eip.app_eip.public_ip}
4. Once DNS propagates, run SSL setup: 
   sudo certbot --nginx -d ${var.domain_name}
EOF
}