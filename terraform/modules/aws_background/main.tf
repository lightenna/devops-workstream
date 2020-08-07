#
# aws_background
# Create the VPC to contain our hosts
# See docs/credits.md for contact/support details; hacked together by Alex Stanhope
#

# Specify the provider and access details
provider "aws" {
  region = var.aws_region
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Our default security group to access instances over SSH within the subnet
resource "aws_security_group" "simple" {
  name        = "devops_secg_simple${var.unique_append}"
  description = "Enabled inbound SSH from within the subnet only"
  vpc_id      = aws_vpc.default.id

  # SSH access from within the VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a second security group just for the bastion host
resource "aws_security_group" "bastion" {
  name        = "devops_secg_bastion${var.unique_append}"
  description = "Enabled inbound SSH from anywhere"
  vpc_id      = aws_vpc.default.id

  # SSH access from within anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}${var.unique_append}"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "bastion" {
  connection {
    type = "ssh"

    # default username for our AMI, connect using local SSH agent
    user = "centos"
    host = self.public_ip
  }

  # create a tiny instance
  instance_type = "t2.micro"

  # lookup the correct AMI based on the region
  ami = var.aws_amis[var.aws_region]

  # the name of our SSH keypair we created
  key_name = aws_key_pair.auth.id

  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = aws_subnet.default.id

  root_block_device {
    volume_type           = "gp2" # general-purpose SSD
    volume_size           = "8"   # 8GB, 0.8 * $1.16/month EBS storage cost
    delete_on_termination = "true"
  }

  # tag for testing purposes
  tags = {
    Name = "bastion${var.unique_append}"
  }

  # update as AMI may be out-of-date
  # update as AMI may be out-of-date
  provisioner "remote-exec" {
    inline = [
    ]
    #"sudo yum -y update",
  }
}

