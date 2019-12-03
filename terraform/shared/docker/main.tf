#
# docker
# Create a docker host
# See docs/credits.md for contact/support details; hacked together by Alex Stanhope
#

provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "docker_host" {
  connection {
    type = "ssh"
    # indirect all requests via the bastion host
    bastion_host = var.bastion_host

    # connect from the bastion using our internal (private) IP, otherwise default to inaccessible public IP
    host = self.private_ip

    # default username for our AMI, connect using local SSH agent
    user = "centos"
  }

  # create a tiny instance
  instance_type = "t2.micro"

  # lookup the correct AMI based on the region
  ami = var.aws_ami

  # the name of our SSH keypair we created
  key_name = var.key_name

  vpc_security_group_ids = [var.aws_security_group_id]
  subnet_id              = var.aws_subnet_id

  root_block_device {
    volume_type           = "gp2" # general-purpose SSD
    volume_size           = "8"   # 8GB, 0.8 * $1.16/month EBS storage cost
    delete_on_termination = "true"
  }

  # tag for testing purposes
  tags = {
    Name = var.host_name
  }

  # install docker pre-requisites, docker [latest] and update everything
  # install docker pre-requisites, docker [latest] and update everything
  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y yum-utils device-mapper-persistent-data lvm2",
      "sudo yum-config-manager --add-repo ${var.docker_yum_repo_url}",
      "sudo yum install -y docker-ce",
      "sudo adduser dockeruser",
      "sudo groupadd docker",
      "sudo usermod -aG docker dockeruser",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo hostnamectl set-hostname ${var.host_name}.${var.local_domain}",
    ]
  }

  # install docker-compose
  # install docker-compose
  provisioner "remote-exec" {
    inline = [
      "sudo curl -L ${var.docker_compose_binary_url_root}-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose",
      "sudo chown dockeruser:dockeruser /usr/local/bin/docker-compose",
      "sudo chmod 700 /usr/local/bin/docker-compose",
    ]
  }
}

