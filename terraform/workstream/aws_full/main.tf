#
# root module
# Creates an array of examples to demonstrate the tools
# See docs/credits.md for contact/support details; hacked together by Alex Stanhope
#

# store state locally for shared IAC to avoid bootstrapping
terraform {
  backend "local" {
  }
}

resource "random_string" "unique_key" {
  length  = 8
  upper = false
  special = false
}

locals {
  # use a unique ID for all resources based on a random string unless one is specified
  unique_append = var.unique_id == "" ? "-${random_string.unique_key.result}" : "-${var.unique_id}"
}

# set up the AWS environment
module "aws_background" {
  source        = "../../modules/aws_background"
  unique_append = local.unique_append
  aws_region    = var.aws_region
  key_name      = var.key_name
}

#
# Example: Packer
#

# create an packer-managed host
# @requires module "aws_background"
module "packer" {
  source     = "../../modules/packer"
  host_name  = "packed${local.unique_append}"
  aws_region = var.aws_region

  # use the fields passed back from aws_background for guaranteed consistency
  bastion_host          = module.aws_background.aws_bastion_public_ip
  key_name              = module.aws_background.aws_key_pair_id
  aws_security_group_id = module.aws_background.aws_security_group_id
  aws_subnet_id         = module.aws_background.aws_subnet_id
  aws_vpc_id            = module.aws_background.aws_vpc_id
}

# output command for accessing host by SSH
output "ssh_command_packed" {
  value = module.packer.instantiated_host_ssh_command
}

#
# Example: Puppet
#

# create a [masterless] puppetted host
# @requires module "aws_background"
module "puppetmless" {
  source     = "../../shared/create-aws-vm-puppetmless"
  host_name  = "puppetmless${local.unique_append}"
  aws_region = var.aws_region

  # use the fields passed back from aws_background for guaranteed consistency
  aws_ami               = module.aws_background.aws_ami_id
  bastion_host          = module.aws_background.aws_bastion_public_ip
  key_name              = module.aws_background.aws_key_pair_id
  aws_security_group_id = module.aws_background.aws_security_group_id
  aws_subnet_id         = module.aws_background.aws_subnet_id
  puppet_environment    = "workstream"
}

# output command for accessing host by SSH
output "ssh_command_puppetmless" {
  value = module.puppetmless.instantiated_host_ssh_command
}

# create a puppetmaster (using the same masterless puppet terraform module as above)
# @requires module "aws_background"
module "puppetmaster" {
  source    = "../../shared/create-aws-vm-puppetmless"
  host_name = "puppetmaster${local.unique_append}"

  # use the puppetmaster manifest to define the config
  aws_region = var.aws_region

  # use the fields passed back from aws_background for guaranteed consistency
  aws_ami               = module.aws_background.aws_ami_id
  bastion_host          = module.aws_background.aws_bastion_public_ip
  key_name              = module.aws_background.aws_key_pair_id
  aws_security_group_id = module.aws_background.aws_security_group_id
  aws_subnet_id         = module.aws_background.aws_subnet_id
  puppet_environment    = "workstream"
}

# output command for accessing host by SSH
output "ssh_command_puppetmaster" {
  value = module.puppetmaster.instantiated_host_ssh_command
}

#
# Example: Ansible
#

# create an ansible-managed host
# @requires module "aws_background"
module "ansiblelocal" {
  source    = "../../modules/ansiblelocal"
  host_name = "ansiblelocal${local.unique_append}"

  # use the main playbook to define the config
  manifest_name = "site.yml"
  aws_region    = var.aws_region

  # use the fields passed back from aws_background for guaranteed consistency
  aws_ami               = module.aws_background.aws_ami_id
  bastion_host          = module.aws_background.aws_bastion_public_ip
  key_name              = module.aws_background.aws_key_pair_id
  aws_security_group_id = module.aws_background.aws_security_group_id
  aws_subnet_id         = module.aws_background.aws_subnet_id
}

# output command for accessing host by SSH
output "ssh_command_ansiblelocal" {
  value = module.ansiblelocal.instantiated_host_ssh_command
}

# create an ansible-managed host
# @requires module "aws_background"
module "ansiblecontrol" {
  source    = "../../modules/ansiblecontrol"
  host_name = "ansiblecontrol${local.unique_append}"

  # use the main playbook to define the config
  manifest_name = "site.yml"
  aws_region    = var.aws_region

  # use the fields passed back from aws_background for guaranteed consistency
  aws_ami               = module.aws_background.aws_ami_id
  bastion_host          = module.aws_background.aws_bastion_public_ip
  key_name              = module.aws_background.aws_key_pair_id
  aws_security_group_id = module.aws_background.aws_security_group_id
  aws_subnet_id         = module.aws_background.aws_subnet_id
}

# output command for accessing host by SSH
output "ssh_command_ansiblecontrol" {
  value = module.ansiblecontrol.instantiated_host_ssh_command
}

#
# Example: docker
#

# create a docker host
# @requires module "aws_background"
module "dockerhost" {
  source     = "../../modules/docker"
  host_name  = "dockerhost${local.unique_append}"
  aws_region = var.aws_region

  # use the fields passed back from aws_background for guaranteed consistency
  aws_ami               = module.aws_background.aws_ami_id
  bastion_host          = module.aws_background.aws_bastion_public_ip
  key_name              = module.aws_background.aws_key_pair_id
  aws_security_group_id = module.aws_background.aws_security_group_id
  aws_subnet_id         = module.aws_background.aws_subnet_id
}

# output command for accessing host by SSH
output "ssh_command_dockerhost" {
  value = module.dockerhost.instantiated_host_ssh_command
}

