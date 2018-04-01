#
# root module
# Creates an array of examples to demonstrate the tools
# See docs/credits.md for contact/support details; hacked together by Alex Stanhope
#

# set up the AWS environment
module "aws_background" {
  source = "./aws_background"
  aws_region = "${var.aws_region}"
  key_name = "${var.key_name}"
}

#
# Example: Packer
#

# create an packer-managed host
# @requires module "aws_background"
module "packer" {
  source = "./packer"
  host_name = "packed"
  aws_region = "${var.aws_region}"
  # use the fields passed back from aws_background for guaranteed consistency
  bastion_host = "${module.aws_background.aws_bastion_public_ip}"
  key_name = "${module.aws_background.aws_key_pair_id}"
  aws_security_group_id = "${module.aws_background.aws_security_group_id}"
  aws_subnet_id = "${module.aws_background.aws_subnet_id}"
}
# output command for accessing host by SSH
output "ssh_command_packed" {
  value = "${module.packer.instantiated_host_ssh_command}"
}

#
# Example: Puppet
#

# create a [masterless] puppetted host
# @requires module "aws_background"
module "puppetmless" {
  source = "./puppetmless"
  host_name = "puppetmless"
  manifest_name = "host-puppetmless.pp"
  aws_region = "${var.aws_region}"
  # use the fields passed back from aws_background for guaranteed consistency
  aws_ami = "${module.aws_background.aws_ami_id}"
  bastion_host = "${module.aws_background.aws_bastion_public_ip}"
  key_name = "${module.aws_background.aws_key_pair_id}"
  aws_security_group_id = "${module.aws_background.aws_security_group_id}"
  aws_subnet_id = "${module.aws_background.aws_subnet_id}"
}
# output command for accessing host by SSH
output "ssh_command_puppetmless" {
  value = "${module.puppetmless.instantiated_host_ssh_command}"
}

# create a puppetmaster (using the same masterless puppet terraform module as above)
# @requires module "aws_background"
module "puppetmaster" {
  source = "./puppetmless"
  host_name = "puppetmaster"
  # use the puppetmaster manifest to define the config
  manifest_name = "host-puppetmaster.pp"
  aws_region = "${var.aws_region}"
  # use the fields passed back from aws_background for guaranteed consistency
  aws_ami = "${module.aws_background.aws_ami_id}"
  bastion_host = "${module.aws_background.aws_bastion_public_ip}"
  key_name = "${module.aws_background.aws_key_pair_id}"
  aws_security_group_id = "${module.aws_background.aws_security_group_id}"
  aws_subnet_id = "${module.aws_background.aws_subnet_id}"
}
# output command for accessing host by SSH
output "ssh_command_puppetmaster" {
  value = "${module.puppetmaster.instantiated_host_ssh_command}"
}

# create a host puppetted by connecting to puppetmaster
# @requires module "aws_background"
module "puppetmastered" {
  source = "./puppetmastered"
  host_name = "puppetmastered"
  aws_region = "${var.aws_region}"
  # use the fields passed back from aws_background for guaranteed consistency
  aws_ami = "${module.aws_background.aws_ami_id}"
  bastion_host = "${module.aws_background.aws_bastion_public_ip}"
  key_name = "${module.aws_background.aws_key_pair_id}"
  aws_security_group_id = "${module.aws_background.aws_security_group_id}"
  aws_subnet_id = "${module.aws_background.aws_subnet_id}"
}
# output command for accessing host by SSH
output "ssh_command_puppetmastered" {
  value = "${module.puppetmastered.instantiated_host_ssh_command}"
}

#
# Example: Ansible
#

# create an ansible-managed host
# @requires module "aws_background"
module "ansiblelocal" {
  source = "./ansible"
  host_name = "ansiblelocal"
  # use the main playbook to define the config
  manifest_name = "site.yml"
  aws_region = "${var.aws_region}"
  # use the fields passed back from aws_background for guaranteed consistency
  aws_ami = "${module.aws_background.aws_ami_id}"
  bastion_host = "${module.aws_background.aws_bastion_public_ip}"
  key_name = "${module.aws_background.aws_key_pair_id}"
  aws_security_group_id = "${module.aws_background.aws_security_group_id}"
  aws_subnet_id = "${module.aws_background.aws_subnet_id}"
}
# output command for accessing host by SSH
output "ssh_command_ansiblelocal" {
  value = "${module.ansiblelocal.instantiated_host_ssh_command}"
}

#
# Example: docker
#

# create a docker host
# @requires module "aws_background"
module "dockerhost" {
  source = "./docker"
  host_name = "dockerhost"
  aws_region = "${var.aws_region}"
  # use the fields passed back from aws_background for guaranteed consistency
  aws_ami = "${module.aws_background.aws_ami_id}"
  bastion_host = "${module.aws_background.aws_bastion_public_ip}"
  key_name = "${module.aws_background.aws_key_pair_id}"
  aws_security_group_id = "${module.aws_background.aws_security_group_id}"
  aws_subnet_id = "${module.aws_background.aws_subnet_id}"
}
# output command for accessing host by SSH
output "ssh_command_dockerhost" {
  value = "${module.dockerhost.instantiated_host_ssh_command}"
}
