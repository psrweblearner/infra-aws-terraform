data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

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
  name_prefix = "starterkit-sandbox"
  common_tags = {
    Project = "starterkit-v3"
    Env     = "sandbox"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

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

resource "aws_security_group" "ec2_sg" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "EC2 SSH/HTTP/HTTPS"
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
  description = "MySQL only from EC2 security group"
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

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-subnets"
  })
}

resource "aws_db_instance" "mysql" {
  identifier                 = var.db_identifier
  allocated_storage          = var.db_allocated_storage
  db_name                    = var.db_name
  engine                     = "mysql"
  engine_version             = "8.0"
  instance_class             = var.db_instance_class
  username                   = var.db_username
  password                   = var.db_password
  db_subnet_group_name       = aws_db_subnet_group.main.name
  vpc_security_group_ids     = [aws_security_group.rds_sg.id]
  publicly_accessible        = false
  skip_final_snapshot        = true
  deletion_protection        = false
  backup_retention_period    = 0
  auto_minor_version_upgrade = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-mysql"
  })
}

resource "aws_s3_bucket" "starterkit" {
  bucket = "${var.s3_bucket_base}-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-bucket"
  })
}

resource "aws_s3_bucket_public_access_block" "starterkit" {
  bucket                  = aws_s3_bucket.starterkit.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "starterkit" {
  bucket = aws_s3_bucket.starterkit.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "ec2_policy" {
  name = "${local.name_prefix}-ec2-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BucketList"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.starterkit.arn]
      },
      {
        Sid    = "BucketObjects"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [
          "${aws_s3_bucket.starterkit.arn}/*"
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

resource "aws_iam_role_policy_attachment" "ec2_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.name_prefix}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name != "" ? var.key_name : null
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg lsb-release mysql-client

    # Install Docker Engine
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $$(. /etc/os-release && echo "$$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list >/dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    usermod -aG docker ubuntu || true

    cat >/opt/starterkit.env <<EOF
    NODE_ENV=staging
    DB_HOST=${aws_db_instance.mysql.address}
    DB_PORT=${aws_db_instance.mysql.port}
    DB_NAME=${var.db_name}
    DB_USER=${var.db_username}
    DB_PASSWORD=${var.db_password}
    S3_BUCKET=${aws_s3_bucket.starterkit.bucket}
    AWS_REGION=${var.aws_region}
    API_DOMAIN_NAME=${var.api_domain_name}
    GITHUB_BRANCH=${var.github_branch}
    GHCR_IMAGE=${var.ghcr_image}
    GHCR_TAG=${var.ghcr_tag}
    GHCR_USERNAME=${var.ghcr_username}
    GHCR_TOKEN=${var.ghcr_token}
    APP_CONTAINER_PORT=${var.app_container_port}
    # Common alternatives used by many Sequelize apps:
    MYSQL_HOST=${aws_db_instance.mysql.address}
    MYSQL_PORT=${aws_db_instance.mysql.port}
    MYSQL_DATABASE=${var.db_name}
    MYSQL_USER=${var.db_username}
    MYSQL_PASSWORD=${var.db_password}
    EOF
    chmod 600 /opt/starterkit.env

    cat >/usr/local/bin/starterkit-docker-deploy.sh <<'EOF'
    #!/bin/bash
    set -euxo pipefail

    source /opt/starterkit.env

    echo "$${GHCR_TOKEN}" | docker login ghcr.io -u "$${GHCR_USERNAME}" --password-stdin
    docker pull "$${GHCR_IMAGE}:$${GHCR_TAG}"

    # Run migrations inside image if sequelize-cli exists there.
    docker run --rm --env-file /opt/starterkit.env "$${GHCR_IMAGE}:$${GHCR_TAG}" sh -c "npx sequelize-cli db:migrate" || true

    docker rm -f starterkit-app || true
    docker run -d \
      --name starterkit-app \
      --restart unless-stopped \
      --env-file /opt/starterkit.env \
      -p 80:$${APP_CONTAINER_PORT} \
      "$${GHCR_IMAGE}:$${GHCR_TAG}"

    docker image prune -f || true
    EOF

    chmod +x /usr/local/bin/starterkit-docker-deploy.sh

    # First deployment
    /usr/local/bin/starterkit-docker-deploy.sh

    cat >/home/ubuntu/DEPLOY_COMMANDS.txt <<EOF
    sudo /usr/local/bin/starterkit-docker-deploy.sh
    sudo docker ps
    sudo docker logs --tail=100 starterkit-app
    sudo docker pull ${var.ghcr_image}:${var.ghcr_tag}
    sudo docker rm -f starterkit-app
    sudo docker run -d --name starterkit-app --restart unless-stopped --env-file /opt/starterkit.env -p 80:${var.app_container_port} ${var.ghcr_image}:${var.ghcr_tag}
    EOF
    chown ubuntu:ubuntu /home/ubuntu/DEPLOY_COMMANDS.txt
  EOT

  tags = merge(local.common_tags, {
    Name = var.instance_name
  })
}

resource "aws_eip" "app" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eip"
  })
}

resource "aws_eip_association" "app" {
  allocation_id = aws_eip.app.id
  instance_id   = aws_instance.app.id
}
