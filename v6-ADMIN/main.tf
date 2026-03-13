data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

locals {
  common_tags = {
    Project = var.name_prefix
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-public-subnet"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.name_prefix}-ec2-sg"
  description = "EC2 access: SSH, HTTP, HTTPS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
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
    Name = "${var.name_prefix}-ec2-sg"
  })
}

data "aws_key_pair" "existing" {
  count    = var.ssh_key_pair_name != "" ? 1 : 0
  key_name = var.ssh_key_pair_name
}

resource "tls_private_key" "main" {
  count     = var.ssh_key_pair_name == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  count      = var.ssh_key_pair_name == "" ? 1 : 0
  key_name   = "${var.name_prefix}-key"
  public_key = tls_private_key.main[0].public_key_openssh

  tags = local.common_tags
}

locals {
  effective_key_name = var.ssh_key_pair_name != "" ? data.aws_key_pair.existing[0].key_name : aws_key_pair.generated_key[0].key_name
}

resource "aws_instance" "admin_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = local.effective_key_name

  user_data_replace_on_change = true
  user_data                   = <<-EOF
              #!/bin/bash
              set -e

              apt-get update
              apt-get install -y docker.io git nginx certbot python3-certbot-nginx

              # Start and enable Docker
              systemctl enable --now docker
              usermod -aG docker ubuntu

              # Configure Nginx for the domain
              cat <<EOT > /etc/nginx/sites-available/app
              server {
                  listen 80;
                  server_name ${var.domain_name};
                  client_max_body_size 100M;

                  location / {
                      proxy_pass http://localhost:${var.app_port};
                      proxy_http_version 1.1;
                      proxy_set_header Upgrade \$http_upgrade;
                      proxy_set_header Connection 'upgrade';
                      proxy_set_header Host \$host;
                      proxy_cache_bypass \$http_upgrade;
                  }
              }
              EOT

              ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/app
              rm -f /etc/nginx/sites-enabled/default
              systemctl restart nginx

              # Automated SSL setup with Certbot (requires DNS -> Elastic IP first)
              certbot --nginx -d ${var.domain_name} --non-interactive --agree-tos -m webmaster@${var.domain_name} --redirect || true
              EOF

  tags = merge(local.common_tags, {
    Name = var.instance_name
  })
}

resource "aws_eip" "admin_eip" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-eip"
  })
}

resource "aws_eip_association" "admin_eip_assoc" {
  allocation_id = aws_eip.admin_eip.id
  instance_id   = aws_instance.admin_server.id
}
