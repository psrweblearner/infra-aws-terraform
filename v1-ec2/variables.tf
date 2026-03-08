variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing AWS key pair name"
  type        = string
  default     = ""
}

variable "instance_name" {
  description = "Name tag for EC2"
  type        = string
  default     = "learning-v1-ec2"
}
