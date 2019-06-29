#
# packer
# Create a host from a packed AMI
# See docs/credits.md for contact/support details; hacked together by Alex Stanhope
#

provider "aws" {
  region = "${var.aws_region}"
}

# build AMIs
module "pack_amis" {
  source = "../pack_amis"
  aws_region = "${var.aws_region}"
  aws_vpc_id = "${var.aws_vpc_id}"
  aws_subnet_id = "${var.aws_subnet_id}"
}

# create a simple instance from our packed image
resource "aws_instance" "packed_host" {
  connection {
    # indirect all requests via the bastion host
    bastion_host = "${var.bastion_host}"
    # connect from the bastion using our internal (private) IP, otherwise default to inaccessible public IP
    host = "${self.private_ip}"
    # default username for our AMI, connect using local SSH agent
    user = "centos"
  }

  # use AMI from pack_amis
  ami = "${module.pack_amis.packed_ami_centos_updated_id}"
  # other aws_instance variables as per template
  instance_type = "t2.micro"
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

  # no need to update (already done by packer), but set hostname
  provisioner "remote-exec" {
    inline = [
      # enable SELinux
      "sudo sed -i -e \"s/^SELINUX=enforcing/SELINUX=disabled/g\" /etc/selinux/config",
      # set the hostname
      "sudo hostnamectl set-hostname ${var.host_name}.${var.local_domain}",
    ]
  }
}
