# ---------------- VPC ----------------
resource "aws_vpc" "shopnest_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "shopnest-vpc"
  }
}

# ---------------- Public Subnet ----------------
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.shopnest_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "shopnest-public-subnet"
  }
}

# ---------------- Internet Gateway ----------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.shopnest_vpc.id
}

# ---------------- Route Table ----------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.shopnest_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ---------------- Security Group ----------------
resource "aws_security_group" "shopnest_sg" {
  name   = "shopnest-sg"
  vpc_id = aws_vpc.shopnest_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------- EC2 ----------------
resource "aws_instance" "shopnest_ec2" {

  ami           = var.ami_id          # 🔥 Takes value from variables.tf
  instance_type = var.instance_type   # 🔥 From variables.tf
  key_name      = var.key_name        # 🔥 From variables.tf

  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.shopnest_sg.id]
  
  # 🔥 INTERNAL STORAGE (ROOT DISK)
  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install docker.io docker-compose git -y
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker ubuntu
              newgrp docker
              EOF

  tags = {
    Name = "shopnest-ec2"
  }
}
