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
  # access_key = ""
  # secret_key = ""

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

# Create security group for nginx proxy
resource "aws_security_group" "nginx_proxy_sg" {
  name        = "nginx-proxy-sg"
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
  egress {
    description = "Allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create security group for frontend - allow SSH from nginx only
resource "aws_security_group" "frontend_sg" {
  name        = "frontend-sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.vpc_fp.id
  ingress {
    description     = "Allow SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_proxy_sg.id] #Allow SSH from nginx only
  }
  ingress {
    description = "Allow HTTP from anywhere"
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

# Create security group for backend 
resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Allow app traffic to backend"
  vpc_id      = aws_vpc.vpc_fp.id
  ingress {
    description     = "Allow SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_proxy_sg.id] #Allow SSH from nginx only
  }
  ingress {
    description = "Allow app traffic from frontend to backend on port 5000"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"] # frontend subnet cidr_block
  }
  egress {
    description = "default"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create security group for mongodb server
resource "aws_security_group" "mongodb_sg" {
  name        = "mongodb-sg"
  description = "Allow app traffic to access the server"
  vpc_id      = aws_vpc.vpc_fp.id

  ingress {
    description = "Allow app traffic to access the server on port 27017"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }

  ingress {
    description     = "Allow SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_proxy_sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# # Create security group for jenkins 
# resource "aws_security_group" "jenkins_sg_fp" {
#   name        = "jenkins-sg-fp"
#   description = "Allow app traffic to deploy to app to instances"
#   vpc_id      = aws_vpc.vpc_fp.id
#   # ingress {
#   #   description = "Allow app traffic to access the server on port 27017"
#   #   from_port   = 27017
#   #   to_port     = 27017
#   #   protocol    = "tcp"
#   #   cidr_blocks = ["10.0.2.0/24"] # Private subnet cidr_block
#   }

# # Create ec2 for deployment using Jenkins
# resource "aws_instance" "jenkins_fp" {
#   ami                         = "ami-020cba7c55df1f615"
#   instance_type = "t2.micro"
#   key_name = var.key_pair
#   subnet_id                   = aws_subnet.public_subnet_fp.id
#   associate_public_ip_address = true
#   # vpc_security_group_ids = 
#   # user_data = {
#    tags = {
#     Name = "Jenkins-fp"

#   }
#   }


# Create ec2 load balancer nginx
resource "aws_instance" "nginx_proxy" {
  ami                         = "ami-020cba7c55df1f615"
  instance_type               = "t2.micro"
  key_name                    = var.key_pair
  subnet_id                   = aws_subnet.public_subnet_fp.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.nginx_proxy_sg.id]
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
  vpc_security_group_ids      = [aws_security_group.frontend_sg.id]
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
  vpc_security_group_ids      = [aws_security_group.frontend_sg.id]
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
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
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
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
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
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  tags = {
    Name = "backend-instance-3"
  }
}

# Create private NLB
resource "aws_lb" "private_lb_fp" {
  name               = "private-lb-fp"
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.private_subnet_fp.id]
  tags = {
    Name = "private-lb-fp"
  }
}

# Defines Backend targets
resource "aws_lb_target_group" "backend_tg" {
  name     = "backend-tg"
  port     = 5000
  protocol = "TCP"
  vpc_id   = aws_vpc.vpc_fp.id
}

# Port Forward to backend tg
resource "aws_lb_listener" "private_nlb_listener" {
  load_balancer_arn = aws_lb.private_lb_fp.arn
  port              = 5000
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

# Attach backend EC2 instance 1
resource "aws_lb_target_group_attachment" "backend_attachment_1" {
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.backend_instance_1.id
  port             = 5000
}

# Attach backend EC2 instance 2
resource "aws_lb_target_group_attachment" "backend_attachment_2" {
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.backend_instance_2.id
  port             = 5000
}

# Attach backend EC2 instance 3
resource "aws_lb_target_group_attachment" "backend_attachment_3" {
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.backend_instance_3.id
  port             = 5000
}

# Create ec2 mongodb server
resource "aws_instance" "mongodb_server" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  key_name               = var.key_pair
  subnet_id              = aws_subnet.private_subnet_fp.id
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
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



