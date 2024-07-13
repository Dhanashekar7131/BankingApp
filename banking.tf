terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "proj-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "proj-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "proj-ig" {
  vpc_id = aws_vpc.proj-vpc.id

  tags = {
    Name = "proj-ig"
  }
}

# Subnet
resource "aws_subnet" "proj-subnet" {
  vpc_id            = aws_vpc.proj-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "proj-subnet"
  }
}

# Route Table
resource "aws_route_table" "proj-rt" {
  vpc_id = aws_vpc.proj-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.proj-ig.id
  }

  tags = {
    Name = "proj-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "proj-rt-sub-assoc" {
  subnet_id      = aws_subnet.proj-subnet.id
  route_table_id = aws_route_table.proj-rt.id
}

# Security Group
resource "aws_security_group" "proj-sg" {
  vpc_id = aws_vpc.proj-vpc.id

  # Ingress rules
  ingress {
    description = "Allow SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all inbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "proj-sg"
  }
}
# Network Interface
resource "aws_network_interface" "proj-ni" {
  subnet_id       = aws_subnet.proj-subnet.id
  private_ips     = ["10.0.1.10"]
  security_groups = [aws_security_group.proj-sg.id]

  tags = {
    Name = "proj-ni"
  }
}
# EC2 Instance
resource "aws_instance" "Deployment_server" {
  ami           = "ami-0a0e5d9c7acc336f1"  # Replace with your AMI ID
  instance_type = "t2.micro"
  key_name      = "keypair"                # Replace with your key pair name
  subnet_id     = aws_subnet.proj-subnet.id

  tags = {
    Name = "Deployment_Server"
  }
}

# Elastic IP
resource "aws_eip" "proj-eip" {
  vpc               = true
  instance          = aws_instance.Deployment_server.id
  network_interface = aws_network_interface.proj-ni.id

  tags = {
    Name = "proj-eip"
  }
}
