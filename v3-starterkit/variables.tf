variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.30.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR block"
  type        = string
  default     = "10.30.1.0/24"
}

variable "private_subnet_a_cidr" {
  description = "Private subnet A CIDR block"
  type        = string
  default     = "10.30.2.0/24"
}

variable "private_subnet_b_cidr" {
  description = "Private subnet B CIDR block"
  type        = string
  default     = "10.30.3.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "EC2 Name tag"
  type        = string
  default     = "starterkit-sandbox-ec2"
}

variable "key_name" {
  description = "Existing AWS key pair name"
  type        = string
  default     = ""
}

variable "db_identifier" {
  description = "RDS identifier"
  type        = string
  default     = "sandbox-mysql"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "starterkit"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "starterkit_admin"
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
  description = "RDS storage (GB)"
  type        = number
  default     = 20
}

variable "s3_bucket_base" {
  description = "Base bucket name (unique suffix is auto-added)"
  type        = string
  default     = "starterkit-2026"
}

variable "api_domain_name" {
  description = "Optional public API domain (for env/use in app)"
  type        = string
  default     = ""
}

variable "ghcr_image" {
  description = "GHCR image path, e.g. ghcr.io/org/repo"
  type        = string
}

variable "ghcr_tag" {
  description = "Image tag to deploy (staging/latest)"
  type        = string
  default     = "staging"
}

variable "ghcr_username" {
  description = "GitHub username/org used to login to GHCR"
  type        = string
}

variable "ghcr_token" {
  description = "GitHub token with read:packages to pull GHCR image"
  type        = string
  sensitive   = true
}

variable "github_branch" {
  description = "Branch name used to produce image tag updates"
  type        = string
  default     = "staging"
}

variable "app_container_port" {
  description = "Internal port exposed by containerized Node app"
  type        = number
  default     = 3000
}
