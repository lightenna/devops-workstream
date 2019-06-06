#
# puppetmless
# Create a host, transfer manifests and call puppet apply
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

  root_block_device {
    volume_type = "gp2" # general-purpose SSD
    volume_size = "8" # 8GB, 0.8 * $1.16/month EBS storage cost
    delete_on_termination = "true"
  }

  # tag for testing purposes
  tags = {
    Name = "${var.host_name}"
  }

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
  # transfer local puppet manifests to host
  provisioner "file" {
    source      = "../puppet"
    # transfer to intermediary folder
    destination = "/tmp/puppet-additions"
    # can't go straight to final destination because user doesn't have access
    # and "file" provisioners have no sudo escalation
  }
  provisioner "remote-exec" {
    inline = [
      # merge into single puppet folder
      "sudo mv /tmp/puppet-additions/* /etc/puppet/",
    ]
  }
  # kick off (masterless) puppet run on host
  provisioner "remote-exec" {
    inline = [
      # run puppet masterless but using community and local modules
      "sudo puppet apply -dvt --modulepath=/etc/puppet/modules --modulepath=/etc/puppet/environments/workstream/modules /etc/puppet/environments/workstream/manifests/${var.manifest_name} > /home/centos/puppet_apply.out 2>&1",
      # pull puppet run output back over terraform console channel
      "sudo tail /home/centos/puppet_apply.out"
    ]
  }
}

