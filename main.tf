provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    name = "main"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  count      = length(var.public_cidr)
  cidr_block = element(var.public_cidr, count.index)
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
  tags = {
    name = "main igw"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

resource "aws_route_table_association" "route_association" {
  count          = length(var.public_cidr)
  route_table_id = aws_route_table.route_table.id
  subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
}

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "fetch_ami" {
  owners      = ["amazon"]
  most_recent = true
  name_regex = "^amzn2-ami-hvm-.*x86_64-gp2$"
}

resource "tls_private_key" "rsa-4096-example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "key" {
  content  = tls_private_key.rsa-4096-example.private_key_pem
  filename = "${var.key_path}/${var.file_name}.pem"
}

resource "local_file" "public_key" {
  content  = tls_private_key.rsa-4096-example.public_key_openssh
  filename = "${var.key_path}/${var.file_name}.pub"
}

resource "aws_key_pair" "ssh_key" {
  key_name   = var.file_name
  public_key = tls_private_key.rsa-4096-example.public_key_openssh
}

resource "aws_instance" "webserver-ec2" {
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet[0].id
  ami                         = data.aws_ami.fetch_ami.id
  key_name                    = aws_key_pair.ssh_key.key_name
  instance_type               = "t2.micro"

  user_data = <<EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install nginx1 -y 
    sudo systemctl enable nginx
    sudo systemctl start nginx
    EOF
}