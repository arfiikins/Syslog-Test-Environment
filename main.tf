provider "aws" {
  region     = var.region_aws
}

resource "aws_vpc" "vpc_rsyslog" { # VPC
  cidr_block = var.vpc_cidr_block
  tags = {
    Name  = "${var.project_name}-vpc-rsyslogEnv"
    Shift = var.shift
  }
}

resource "aws_subnet" "pubsub_rsyslog" { # pubsub
  vpc_id                  = aws_vpc.vpc_rsyslog.id
  availability_zone       = var.azone[0]
  cidr_block              = var.pubsubnet
  map_public_ip_on_launch = true
  tags = {
    Name  = "${var.project_name}-pubsub-rsyslogEnv"
    Shift = var.shift
  }
}

resource "aws_internet_gateway" "igw_rsyslog" { # IGW
  vpc_id = aws_vpc.vpc_rsyslog.id
  tags = {
    Name  = "${var.project_name}-igw-rsyslogEnv"
    Shift = var.shift
  }
}

resource "aws_route_table" "pub_rt_rsyslog" { # RTB
  vpc_id = aws_vpc.vpc_rsyslog.id

  route {
    cidr_block = var.anycidr
    gateway_id = aws_internet_gateway.igw_rsyslog.id

  }

  tags = {
    Name  = "${var.project_name}-rtb-rsyslogEnv"
    Shift = var.shift
  }
}

resource "aws_route_table_association" "pubsub_rtb" { # Pubsub -> IGW
  subnet_id      = aws_subnet.pubsub_rsyslog.id
  route_table_id = aws_route_table.pub_rt_rsyslog.id
}

resource "aws_security_group" "rsyslog" { # SG for rsyslog
  name        = "${var.project_name}-rsyslog"
  description = "rsyslog environment security group"
  vpc_id      = aws_vpc.vpc_rsyslog.id

  ingress {
    description = "SSH from my public ip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.mypublicip]
  }
  ingress {
    description = "Syslog over UDP"
    from_port   = 514
    to_port     = 514
    protocol    = "udp"
    cidr_blocks = var.rsyslogregioncidr
  }
  /*ingress {             # uncomment if need TLS
    description = "Syslog over TLS"
    from_port   = 6514
    to_port     = 6514
    protocol    = "tcp"
    cidr_blocks = var.rsyslogregioncidr
  }*/
  ingress {
    description = "Exposed all ports within the subnet (TESTING ONLY)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.pubsub_rsyslog.cidr_block]
  }
  egress {
    description = "Connect outside"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.anycidr]
  }

  tags = {
    Name  = "${var.project_name}-rsyslog-sg"
    Shift = var.shift
  }
}

resource "aws_instance" "rsyslog" { # Rsyslog server (Ubuntu 22.04)
  ami                         = var.ubuntu22-04_ami
  key_name                    = var.kp_name
  subnet_id                   = aws_subnet.pubsub_rsyslog.id
  vpc_security_group_ids      = [aws_security_group.rsyslog.id]
  instance_type               = var.rsyslog_instance_type
  associate_public_ip_address = true

  user_data = file("${path.module}/scripts/rsyslog_udp.sh")

  root_block_device {
    volume_size = 30
    volume_type = var.volume_type
  }

  tags = {
    Name  = "${var.project_name}-server"
    Shift = var.shift
  }
}

# Outputs
output "vpc_id" {
  value = aws_vpc.vpc_rsyslog.id
}

output "public_subnet_id" {
  value = aws_subnet.pubsub_rsyslog.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw_rsyslog.id
}

output "route_table_id" {
  value = aws_route_table.pub_rt_rsyslog.id
}

output "rsyslog_master" {
  value = aws_instance.rsyslog.public_ip
}