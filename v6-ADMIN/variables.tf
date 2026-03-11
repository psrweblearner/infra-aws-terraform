variable "name_prefix" {
  description = "Prefix for naming/tagging AWS resources."
  type        = string
  default     = "starter-kit-admin"
}

variable "aws_region" {
  description = "AWS region (e.g., ap-south-1)."
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

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "EC2 Name tag"
  type        = string
  default     = "starter-kit-admin"
}

variable "domain_name" {
  description = "Admin domain name (e.g., admin.aeonianit.in)."
  type        = string
  default     = "admin.aeonianit.in"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH (22). Use your public IP /32 for best security."
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_port" {
  description = "Local port Nginx proxies to (your Docker app port on the instance)."
  type        = number
  default     = 5000
}

variable "ssh_key_pair_name" {
  description = "Existing AWS EC2 key pair name to reuse (same SSH as v5). If empty, this stack will generate a new key pair and output its private key."
  type        = string
  default     = "starterkit-key"
}
