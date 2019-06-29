#
# ansible
# Create a host, transfer playbooks and configure using ansible
# See docs/credits.md for contact/support details; hacked together by Alex Stanhope
#

provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_instance" "ansible_host" {
  connection {
    # indirect all requests via the bastion host
    bastion_host = "${var.bastion_host}"
    # connect from the bastion using our internal (private) IP, otherwise default to inaccessible public IP
    host = "${self.private_ip}"
    # default username for our AMI, connect using local SSH agent
    user = "centos"
  }

  # create a tiny instance
  instance_type = "t2.micro"

  # lookup the correct AMI based on the region
  ami = "${var.aws_ami}"

  # the name of our SSH keypair we created
  key_name = "${var.key_name}"

  vpc_security_group_ids = ["${var.aws_security_group_id}"]
  subnet_id = "${var.aws_subnet_id}"

  root_block_device {
    volume_type = "gp2" # general-purpose SSD
    volume_size = "8" # 8GB, 0.8 * $1.16/month EBS storage cost
    delete_on_termination = "true"
  }

  # tag for testing purposes
  tags = {
    Name = "${var.host_name}"
  }

  # install ansible and update
  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install deltarpm",
      "sudo yum -y install epel-release",
      #"sudo yum -y update",
      "sudo yum -y install ansible",
      # set the hostname
      "sudo hostnamectl set-hostname ${var.host_name}.${var.local_domain}",
    ]
  }
  # transfer local ansible playbooks to host
  provisioner "file" {
    # relative path from executing terraform module
    source      = "../../ansible"
    # transfer to intermediary folder
    destination = "/tmp/ansible-additions"
    # can't go straight to final destination because user doesn't have access
    # and "file" provisioners have no sudo escalation
  }
  provisioner "remote-exec" {
    inline = [
      # merge into single puppet folder
      "sudo mv /tmp/ansible-additions/* /etc/ansible/",
    ]
  }
  # kick off ansible run on host
  provisioner "remote-exec" {
    inline = [
      # run ansible locally (on remote machine)
      "sudo ansible-playbook /etc/ansible/${var.manifest_name} --connection=local  > /home/centos/ansible_playbook.out 2>&1",
      # pull ansible run output back over terraform console channel
      "sudo tail /home/centos/ansible_playbook.out"
    ]
  }
}

