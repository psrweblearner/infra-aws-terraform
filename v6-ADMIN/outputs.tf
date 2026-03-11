output "ec2_instance_id" {
  description = "Admin EC2 instance ID"
  value       = aws_instance.admin_server.id
}

output "elastic_ip" {
  description = "Elastic IP attached to admin EC2"
  value       = aws_eip.admin_eip.public_ip
}

output "domain_name" {
  description = "Admin domain configured in Nginx/Certbot"
  value       = var.domain_name
}

output "key_pair_name" {
  description = "EC2 key pair name used for SSH"
  value       = local.effective_key_name
}

output "ssh_private_key" {
  description = "Only present when this stack generated a new key pair (ssh_key_pair_name was empty). Save to a file (e.g., id_rsa) and chmod 400."
  value       = try(tls_private_key.main[0].private_key_pem, null)
  sensitive   = true
}

output "ssh_command" {
  description = "SSH command (connect via Elastic IP)"
  value       = "ssh -i id_rsa ubuntu@${aws_eip.admin_eip.public_ip}"
}

output "ssh_key_hint" {
  description = "SSH key hint"
  value       = var.ssh_key_pair_name != "" ? "Reusing existing AWS key pair '${var.ssh_key_pair_name}'. Use the same private key file you already saved from v5 (for example: v5-API/id_rsa)." : "This stack generated a new key. Save the ssh_private_key output to a file named id_rsa and chmod 400 it."
}

output "deployment_instructions" {
  description = "Next steps"
  value       = <<EOF
1) Create/Update DNS A record: ${var.domain_name} -> ${aws_eip.admin_eip.public_ip}
2) If SSL failed (DNS not ready), re-run on instance: sudo certbot --nginx -d ${var.domain_name}
3) SSH: ssh -i id_rsa ubuntu@${aws_eip.admin_eip.public_ip}
EOF
}
