variable "aws_region" {
  description = "AWS region"
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
  description = "EC2 Name tag"
  type        = string
  default     = "learning-v2-ec2"
}

variable "key_name" {
  description = "Existing AWS key pair name for SSH"
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
  description = "RDS master password"
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