variable "name_prefix" {
  description = "A prefix for resource naming to ensure uniqueness and organization."
  type        = string
  default     = "starter-kit"
}

variable "aws_region" {
  description = "The AWS region where resources will be deployed (e.g., us-east-1, ap-south-1)."
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR block for EC2"
  type        = string
  default     = "10.20.1.0/24"
}

variable "private_subnet_a_cidr" {
  description = "Private subnet A CIDR block for RDS"
  type        = string
  default     = "10.20.2.0/24"
}

variable "private_subnet_b_cidr" {
  description = "Private subnet B CIDR block for RDS"
  type        = string
  default     = "10.20.3.0/24"
}


variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "EC2 Name tag. If empty, will default to name_prefix-ec2."
  type        = string
  default     = ""
}

variable "key_name" {
  description = "The name of an existing AWS key pair for SSH access to the EC2 instance. Leave empty to use Session Manager or if no SSH access is needed."
  type        = string
  default     = ""
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "appadmin"
}

variable "db_password" {
  description = "The master password for the RDS database instance. This should be provided via a .tfvars file or environment variable."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "bucket_prefix" {
  description = "Prefix used for S3 bucket naming"
  type        = string
  default     = "learning-v2-app"
}

variable "domain_name" {
  description = "The domain name for the API (e.g., api.aeonianit.in)."
  type        = string
  default     = "api.aeonianit.in"
}