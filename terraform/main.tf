terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"

}

# Create a VPC
resource "aws_vpc" "vpc_fp" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc-fp"
  }
}

# Configure Internet Gateway
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc_fp.id

  tags = {
    Name = "gateway-fp"
  }
}

# Configure NAT gateway
resource "aws_nat_gateway" "nat_gateway_fp" {
  allocation_id = aws_eip.eip_fp.id
  subnet_id     = aws_subnet.public_subnet_fp.id

  tags = {
    Name = "nat-gateway"
  }
}

# Configure Elastic IP required for NAT Gateway
resource "aws_eip" "eip_fp" {
  domain = "vpc"
  tags = {
    Name = "nat-eip"
  }
}

# Route Table for public subnet
resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.vpc_fp.id

  route {
    cidr_block = "0.0.0.0/0" # All outbound internet traffic
    gateway_id = aws_internet_gateway.gateway.id
  }
  tags = {
    Name = "Route-table-public"
  }
}

# Route Table for private subnet
resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.vpc_fp.id

  route {
    cidr_block     = "0.0.0.0/0" # Internet traffic
    nat_gateway_id = aws_nat_gateway.nat_gateway_fp.id
  }
  tags = {
    Name = "Route-table-private"
  }
}

# Route Table association for public subnet
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet_fp.id
  route_table_id = aws_route_table.route_table_public.id
}

# Route Table association for private subnet
resource "aws_route_table_association" "private_rta" {
  subnet_id      = aws_subnet.private_subnet_fp.id
  route_table_id = aws_route_table.route_table_private.id
}

# Create public subnet
resource "aws_subnet" "public_subnet_fp" {
  vpc_id                  = aws_vpc.vpc_fp.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-fp"
  }
}

# Create private subnet
resource "aws_subnet" "private_subnet_fp" {
  vpc_id            = aws_vpc.vpc_fp.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet-fp"
  }
}

# Create security group for project
resource "aws_security_group" "fp_sg" {
  name        = "fp-sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.vpc_fp.id
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Connect to database mongodb"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Connect frontend to backend"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    description = "Connect to site"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create ec2 nginx proxy
resource "aws_instance" "nginx_proxy" {
  ami                         = "ami-020cba7c55df1f615"
  instance_type               = "t2.micro"
  key_name                    = var.key_pair
  subnet_id                   = aws_subnet.public_subnet_fp.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.fp_sg.id]
  user_data = templatefile("nginx-setup.sh.tpl", {
    frontend1_private_ip = aws_instance.frontend_instance_1.private_ip,
    frontend2_private_ip = aws_instance.frontend_instance_2.private_ip
  })
  tags = {
    Name = "nginx-proxy"
  }
}

# Create ec2 frontend-instance-1
resource "aws_instance" "frontend_instance_1" {
  ami                         = "ami-020cba7c55df1f615"
  instance_type               = "t2.micro"
  key_name                    = var.key_pair
  subnet_id                   = aws_subnet.public_subnet_fp.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.fp_sg.id]
  tags = {
    Name = "frontend-instance-1"
  }
}

# Create ec2 frontend-instance-2
resource "aws_instance" "frontend_instance_2" {
  ami                         = "ami-020cba7c55df1f615"
  instance_type               = "t2.micro"
  key_name                    = var.key_pair
  subnet_id                   = aws_subnet.public_subnet_fp.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.fp_sg.id]
  tags = {
    Name = "frontend-instance-2"
  }
}

# Create ec2 backend-instance-1
resource "aws_instance" "backend_instance_1" {
  ami                    = "ami-020cba7c55df1f615"
  instance_type          = "t2.micro"
  key_name               = var.key_pair
  subnet_id              = aws_subnet.private_subnet_fp.id
  vpc_security_group_ids = [aws_security_group.fp_sg.id]
  tags = {
    Name = "backend-instance-1"
  }
}

# Create ec2 backend-instance-2
resource "aws_instance" "backend_instance_2" {
  ami                    = "ami-020cba7c55df1f615"
  instance_type          = "t2.micro"
  key_name               = var.key_pair
  subnet_id              = aws_subnet.private_subnet_fp.id
  vpc_security_group_ids = [aws_security_group.fp_sg.id]
  tags = {
    Name = "backend-instance-2"
  }
}

# Create ec2 backend-instance-3
resource "aws_instance" "backend_instance_3" {
  ami                    = "ami-020cba7c55df1f615"
  instance_type          = "t2.micro"
  key_name               = var.key_pair
  subnet_id              = aws_subnet.private_subnet_fp.id
  vpc_security_group_ids = [aws_security_group.fp_sg.id]
  tags = {
    Name = "backend-instance-3"
  }
}

# Create NLB
resource "aws_lb" "public_lb_fp" {
  name               = "public-lb-fp"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_subnet_fp.id]
  tags = {
    Name = "public-lb-fp"
  }
}

# Port Forward to backend: forward requests to target group
resource "aws_lb_listener" "public_nlb_listener" {
  load_balancer_arn = aws_lb.public_lb_fp.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_targets.arn
  }
}

# Creates NLB target group
resource "aws_lb_target_group" "nlb_targets" {
  name     = "nlb-tg"
  port     = 5000
  protocol = "TCP"
  vpc_id   = aws_vpc.vpc_fp.id
  health_check {
    protocol = "TCP"
    port     = "5000"
  }
}

# Attach backend EC2 instance 1 to target group
resource "aws_lb_target_group_attachment" "backend_attachment_1" {
  target_group_arn = aws_lb_target_group.nlb_targets.arn
  target_id        = aws_instance.backend_instance_1.id
  port             = 5000
}

# Attach backend EC2 instance 2 to target group
resource "aws_lb_target_group_attachment" "backend_attachment_2" {
  target_group_arn = aws_lb_target_group.nlb_targets.arn
  target_id        = aws_instance.backend_instance_2.id
  port             = 5000
}

# Attach backend EC2 instance 3 to target group
resource "aws_lb_target_group_attachment" "backend_attachment_3" {
  target_group_arn = aws_lb_target_group.nlb_targets.arn
  target_id        = aws_instance.backend_instance_3.id
  port             = 5000
}

# Create ec2 mongodb server
resource "aws_instance" "mongodb_server" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  key_name               = var.key_pair
  subnet_id              = aws_subnet.private_subnet_fp.id
  vpc_security_group_ids = [aws_security_group.fp_sg.id]
  tags = {
    Name = "mongodb-server"
  }
}

# Create s3 bucket
resource "aws_s3_bucket" "s3_bucket_fp" {
  bucket = "s3-bucket-fp-2025"
  tags = {
    Name        = "s3-bucket-fp"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.s3_bucket_fp.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  depends_on = [aws_s3_bucket.s3_bucket_fp]
}

resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.s3_bucket_fp.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.s3_bucket_fp.arn}/*"
      }
    ]
  })
}





