terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0.1"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  # access_key = ""
  # secret_key = ""
  
}

# Create a VPC
resource "aws_vpc" "vpc_fp" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc_fp"
  }
}

# Create public subnet
resource "aws_subnet" "public_subnet_fp" {
  vpc_id = aws_vpc.vpc_fp.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet_fp"
  }
}

# Create private subnet
resource "aws_subnet" "private_subnet_fp" {
  vpc_id = aws_vpc.vpc_fp.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private_subnet_fp"
  }
}

# Create security group for nginx proxy
resource "aws_security_group" "nginx_proxy_sg" {
  name = "nginx_proxy_sg"
  description = "Allow HTTP traffic"
  vpc_id = aws.vpc_fp.id
  ingress {
    description = "Allow HTTP from anywhere"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

# Create security group for frontend 
resource "aws_security_group" "frontend_sg" {
  name = "frontend_sg"
  description = "Allow HTTP traffic"
  vpc_id = aws.vpc_fp.id
  ingress {
    description = "Allow HTTP from anywhere"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

# Create security group for backend 
resource "aws_security_group" "backend_sg" {
  name = "backend_sg"
  description = "Allow app traffic to backend"
  vpc_id = aws.vpc_fp.id
  ingress {
    description = "Allow app traffic from NLB to backend on port 5000"
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24"] # Public subnet cidr_block
  }
  egress {
    description = "default"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

# Create security group for mongodb server
resource "aws_security_group" "mongodb_sg" {
  name = "mongodb_sg"
  description = "Allow app traffic to access the server"
  vpc_id = aws.vpc_fp.id
  ingress {
    description = "Allow app traffic to access the server on port 27017"
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    cidr_blocks = ["10.0.2.0/24"] # Private subnet cidr_block
  }
}

# # Create ec2 load balancer nginx
# resource "aws_instance" "nginx_proxy" {
#   ami = "ami-020cba7c55df1f615"
#   instance_type = "t2.micro"
#   key_name = var.key_pair
#   subnet_id = aws_subnet.public_subnet_fp.id
#   associate_public_ip_address = true
#   vpc_security_group_ids = [aws_security_group.nginx_proxy_sg]
#   tags = {
#     Name = "nginx_proxy"
#   }
# }

# Create ec2 frontend-instance-1
resource "aws_instance" "frontend-instance-1" {
  ami = "ami-020cba7c55df1f615"
  instance_type = "t2.micro"
  key_name = var.key_pair
  subnet_id = aws_subnet.public_subnet_fp.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  tags = {
    Name = "frontend-instance-1"
  }
}

# Create ec2 frontend-instance-2
resource "aws_instance" "frontend-instance-2" {
  ami = "ami-020cba7c55df1f615"
  instance_type = "t2.micro"
  key_name = var.key_pair
  subnet_id = aws_subnet.public_subnet_fp.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  tags = {
    Name = "frontend-instance-2"
  }
}

# Create ec2 backend-instance-1
resource "aws_instance" "backend-instance-1" {
  ami = "ami-020cba7c55df1f615"
  instance_type = "t2.micro"
  key_name = var.key_pair
  subnet_id = aws_subnet.private_subnet_fp.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  tags = {
    Name = "backend-instance-1"
  }
}

# Create ec2 backend-instance-2
resource "aws_instance" "backend-instance-2" {
  ami = "ami-020cba7c55df1f615"
  instance_type = "t2.micro"
  key_name = var.key_pair
  subnet_id = aws_subnet.private_subnet_fp.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  tags = {
    Name = "backend-instance-2"
  }
}

# Create ec2 backend-instance-3
resource "aws_instance" "backend-instance-3" {
  ami = "ami-020cba7c55df1f615"
  instance_type = "t2.micro"
  key_name = var.key_pair
  subnet_id = aws_subnet.private_subnet_fp.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  tags = {
    Name = "backend-instance-3"
  }
}

# # Create private NLB
# resource "aws_instance" "backend-instance-3" {
#   ami = "ami-020cba7c55df1f615"
#   instance_type = "t2.micro"
#   key_name = var.key_pair
#   subnet_id = aws_subnet.private_subnet_fp.id
#   vpc_security_group_ids = [aws_security_group.backend_sg.id]
#   tags = {
#     Name = "backend-instance-3"
#   }
# }

# Create ec2 mongodb server
resource "aws_instance" "mongodb_server" {
  ami = "ami-020cba7c55df1f615"
  instance_type = "t2.micro"
  key_name = var.key_pair
  subnet_id = aws_subnet.private_subnet_fp.id
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  tags = {
    Name = "mongodb_server"
  }
}

# Create s3 bucket
resource "aws_s3_bucket" "s3_bucket_fp" {
  bucket = "s3_bucket_fp_2025" 
  tags = {
    Name = "s3_bucket_fp"
    Environment = "Dev"
  }
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

resource "aws_s3_bucket_public_access_block" "allow_public" {
  bucket = aws_s3_bucket.s3_bucket_fp.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Output block
output "vpc_id" {
  value = aws_vpc.vpc_fp.id
}
