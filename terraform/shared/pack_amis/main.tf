#
# pack_amis
# Create a host, transfer manifests and call puppet apply
# See docs/credits.md for contact/support details; hacked together by Alex Stanhope
#
# Usage
# Integrated
#   module "pack_amis" {
#     aws_region = "${var.aws_region}"
#   }
#
# Standalone
#   terraform apply pack_amis
#


provider "aws" {
  region = "${var.aws_region}"
}

# build AMI using packer (better done with Terraform Enterprise/Atlas, but this works/cheaper)
resource "null_resource" "pack_centos_updated" {
  provisioner "local-exec" {
    command = "packer build -var 'aws_vpc_id=${var.aws_vpc_id}' -var 'aws_subnet_id=${var.aws_subnet_id}' ${path.module}/../../../packer/centos_updated.json"
  }
}

# find the AWS image we just built
data "aws_ami" "centos_updated" {
  most_recent      = true
  owners     = ["self"]
  filter {
    name   = "name"
    values = ["centos-updated-*"]
  }
  # wait for packer run to complete
  depends_on = ["null_resource.pack_centos_updated"]
}
