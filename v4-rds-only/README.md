# v4 RDS Only

This Terraform stack creates a public AWS MySQL RDS instance without EC2 or S3.

## What it creates

- A dedicated VPC
- Two public subnets in different availability zones
- An internet gateway and public route table
- A security group that allows MySQL only from `allowed_mysql_cidrs`
- A publicly accessible MySQL RDS instance

## Before apply

1. Update `terraform.tfvars`.
2. Replace `YOUR_PUBLIC_IP/32` with your real public IP.
3. Add any other office or server CIDR ranges that also need database access.
4. Change `db_password` to a strong password.

## Commands

```powershell
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Outputs

After apply, Terraform prints:

- `rds_endpoint`
- `rds_port`
- `rds_connection_string`

You can then connect from local tools such as MySQL Workbench, DBeaver, or the MySQL CLI.
