terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "HandsonVPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "HandsonVPC"
  }
}

resource "aws_internet_gateway" "HandsonIGW" {
  vpc_id = aws_vpc.HandsonVPC.id

  tags = {
    Name = "HandsonIGW"
  }
}

# Public Subnet
resource "aws_subnet" "HandsonPublicSubnet" {
  vpc_id            = aws_vpc.HandsonVPC.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "HandsonPublicSubnet"
  }
}

# Private Subnet
resource "aws_subnet" "HandsonPrivateSubnet" {
  vpc_id            = aws_vpc.HandsonVPC.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name = "HandsonPrivateSubnet"
  }
}

# Public Route Table
resource "aws_route_table" "HandsonPublicRouteTable" {
  vpc_id = aws_vpc.HandsonVPC.id

  tags = {
    Name = "HandsonPublicRouteTable"
  }
}

# route to IGW
resource "aws_route" "HandsonPublic_IGW_Route" {
  route_table_id         = aws_route_table.HandsonPublicRouteTable.id
  gateway_id             = aws_internet_gateway.HandsonIGW.id
  destination_cidr_block = "0.0.0.0/0"

}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "HandsonPublicSubnet_Association" {
  subnet_id      = aws_subnet.HandsonPublicSubnet.id
  route_table_id = aws_route_table.HandsonPublicRouteTable.id
}

# secruity group
resource "aws_security_group" "HandsonSG" {
  name        = "HandsonSG"
  description = "HandsonSG"
  vpc_id      = aws_vpc.HandsonVPC.id

  dynamic "ingress" {
    for_each = [22, 80, 443, 5000]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "HandsonSG"
  }
}


# EC2 Instance
resource "aws_instance" "HandsonEC2" {
  ami                         = "ami-0aaa5410833273cfe"
  instance_type               = "t2.micro"
  key_name                    = "myfirst"
  subnet_id                   = aws_subnet.HandsonPublicSubnet.id
  vpc_security_group_ids      = [aws_security_group.HandsonSG.id]
  associate_public_ip_address = true

  tags = {
    Name = "HandsonEC2"
  }
}

# Output
output "HandsonEC2_IP" {
  value = aws_instance.HandsonEC2.public_ip
}

output "HandonEC2_DNS" {
  value = aws_instance.HandsonEC2.public_dns
}
