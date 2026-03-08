variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "name_prefix" {
  description = "Prefix used for resource names and tags"
  type        = string
  default     = "rds-v4"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.40.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "Public subnet A CIDR block"
  type        = string
  default     = "10.40.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "Public subnet B CIDR block"
  type        = string
  default     = "10.40.2.0/24"
}

variable "allowed_mysql_cidrs" {
  description = "CIDR blocks allowed to connect to MySQL over the internet"
  type        = list(string)
  default     = []
}

variable "db_identifier" {
  description = "RDS identifier"
  type        = string
  default     = "v4-public-mysql"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "dbadmin"
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
  description = "RDS storage in GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 0
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy"
  type        = bool
  default     = true
}
