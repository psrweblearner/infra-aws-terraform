/*
IMPORTANT OVERVIEW:
- This file creates one connected stack:
  EC2 (public subnet + Elastic IP) <-> RDS (private subnets) and EC2 -> S3 (IAM).
- Connectivity is controlled by VPC/subnets/route tables, security groups, and IAM.

NOT IMPORTANT:
- Tags and naming conventions are optional for behavior, but useful for operations.
*/

/*
SECTION: Base image + shared naming
IMPORTANT:
- AMI data source chooses the latest Ubuntu 22.04 image.
- locals are reused by almost every resource for consistent names/tags.
*/
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  name_prefix = "learning-v2"
  common_tags = {
    Project = "learning-v2-connected"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

/*
SECTION: Network foundation (VPC, subnets, internet route)
IMPORTANT:
- Public subnet hosts EC2.
- Private subnets host RDS through db subnet group.
- Public route table + IGW enables internet access for EC2 and outbound package installs.
*/
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-subnet"
  })
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_a_cidr
  map_public_ip_on_launch = false
  availability_zone       = "${var.aws_region}a"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-a"
  })
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_b_cidr
  map_public_ip_on_launch = false
  availability_zone       = "${var.aws_region}b"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-b"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

/*
SECTION: Security boundaries
IMPORTANT:
- ec2_sg allows inbound 22/80/443.
- rds_sg allows MySQL (3306) only from ec2_sg, creating EC2 -> RDS trust.
*/
resource "aws_security_group" "ec2_sg" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "EC2 access: SSH, HTTP, HTTPS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-sg"
  })
}

resource "aws_security_group" "rds_sg" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Allow MySQL from EC2 security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-sg"
  })
}

/*
SECTION: Database layer
IMPORTANT:
- RDS is private (`publicly_accessible = false`) and placed in private subnets.
- db_subnet_group ties RDS to private_a/private_b.
- EC2 connects using RDS endpoint and SG rules.

LESS IMPORTANT FOR LEARNING:
- backup_retention_period = 0 and skip_final_snapshot = true optimize easy rollback, not production safety.
*/
resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-subnet-group"
  })
}

resource "aws_db_instance" "app_db" {
  identifier              = "${local.name_prefix}-mysql"
  allocated_storage       = var.db_allocated_storage
  db_name                 = var.db_name
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.db_instance_class
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds"
  })
}

/*
SECTION: Object storage layer
IMPORTANT:
- S3 bucket is private with public access blocked.
- Bucket name is globally unique via random suffix.
*/
resource "aws_s3_bucket" "app_bucket" {
  bucket = "${var.bucket_prefix}-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-bucket"
  })
}

resource "aws_s3_bucket_public_access_block" "app_bucket_pab" {
  bucket                  = aws_s3_bucket.app_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "app_bucket_versioning" {
  bucket = aws_s3_bucket.app_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

/*
SECTION: IAM for EC2 -> S3 (+ read-only RDS metadata)
IMPORTANT:
- EC2 role + instance profile are attached to the instance.
- Policy grants scoped bucket access and rds:DescribeDBInstances.
- This is the identity link that connects EC2 to S3 without hardcoded keys.
*/
resource "aws_iam_role" "ec2_role" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_app_policy" {
  name = "${local.name_prefix}-ec2-app-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3AppBucketAccess"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = [
          aws_s3_bucket.app_bucket.arn
        ]
      },
      {
        Sid    = "S3ObjectAccess"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [
          "${aws_s3_bucket.app_bucket.arn}/*"
        ]
      },
      {
        Sid      = "RdsDescribe"
        Effect   = "Allow"
        Action   = ["rds:DescribeDBInstances"]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_app_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

/*
SECTION: Compute layer
IMPORTANT:
- EC2 runs in the public subnet and receives IAM instance profile.
- user_data writes runtime connection values (bucket + DB endpoint) to /home/ubuntu/app.env.

LESS IMPORTANT:
- key_name is optional; keep empty if you do not need SSH key access.
*/
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name != "" ? var.key_name : null
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOT
    #!/bin/bash
    cat >/home/ubuntu/app.env <<EOF
    APP_BUCKET=${aws_s3_bucket.app_bucket.bucket}
    DB_HOST=${aws_db_instance.app_db.address}
    DB_NAME=${var.db_name}
    DB_USER=${var.db_username}
    EOF
    chown ubuntu:ubuntu /home/ubuntu/app.env
  EOT

  tags = merge(local.common_tags, {
    Name = var.instance_name
  })
}

/*
SECTION: Public address
IMPORTANT:
- EIP gives stable public IP.
- aws_eip_association explicitly links EIP to EC2.
*/
resource "aws_eip" "app_eip" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eip"
  })
}

resource "aws_eip_association" "app_eip_assoc" {
  allocation_id = aws_eip.app_eip.id
  instance_id   = aws_instance.app_server.id
}
