#
# puppetmastered
# Create a host, connect to puppetmaster and puppet
# See docs/credits.md for contact/support details; hacked together by Alex Stanhope
#

provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_instance" "puppetted_host" {
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

  # install puppet and update
  provisioner "remote-exec" {
    inline = [
      # install an up-to-date puppet agent
      "sudo rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm",
      "sudo yum -y install epel-release",
      "sudo yum -y install deltarpm",
      "sudo yum -y update",
      "sudo yum -y install puppet",
      # set the hostname
      "sudo hostnamectl set-hostname ${var.host_name}.${var.local_domain}",
    ]
  }
  # @todo connect to master
  # kick off puppet run on host
  provisioner "remote-exec" {
    inline = [
      # @todo run puppet in daemon mode
    ]
  }
}

