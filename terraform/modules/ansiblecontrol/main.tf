#
# ansible control node
# Create a host (control node), transfer playbooks, create multiple slaves, execute playbooks on slaves
# See docs/credits.md for contact/support details; hacked together by Alex Stanhope
#

provider "aws" {
  region = var.aws_region
}

# create a target node
resource "aws_instance" "ansible_target_node" {
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
    Name = "targetfor-${var.host_name}"
  }

  # install ansible and update
  # install ansible and update
  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install deltarpm",
      "sudo yum -y install epel-release",
      "sudo hostnamectl set-hostname targetfor-${var.host_name}.${var.local_domain}",
    ]
  }
}

# create a control node
resource "aws_instance" "ansible_control_node" {
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

  # install ansible and update
  # install ansible and update
  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install deltarpm",
      "sudo yum -y install epel-release",
      "sudo yum -y install ansible",
      "sudo hostnamectl set-hostname ${var.host_name}.${var.local_domain}",
    ]
  }

  # transfer local ansible playbooks to host
  # transfer local ansible playbooks to host
  provisioner "file" {
    # relative path from executing terraform module
    source = "../../ansible"

    # transfer to intermediary folder
    destination = "/tmp/ansible-additions"
    # can't go straight to final destination because user doesn't have access
    # and "file" provisioners have no sudo escalation
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/ansible-additions/* /etc/ansible/",
    ]
    # @todo execute ansible to push config to target
  }

  # can't create the control node until we've got a target to push config to
  depends_on = [aws_instance.ansible_target_node]
}

