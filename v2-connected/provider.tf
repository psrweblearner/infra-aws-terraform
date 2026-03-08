/*
IMPORTANT:
- Pins Terraform/AWS/Random versions for reproducible runs.
- Region comes from var.aws_region and controls where every resource is created.

NOT IMPORTANT FOR CONNECTIVITY:
- Exact provider version ranges can be changed later if needed.
*/
terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
