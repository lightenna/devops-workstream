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

provider "azurerm" {}

resource "random_string" "unique_key" {
  length = 8
  special = false
}

locals {
  # use a unique ID for all resources based on a random string unless one is specified
  unique_append = "${ var.unique_id == "" ? "-${random_string.unique_key.result}" : "${var.unique_id}"}"
  hostbase = "${terraform.workspace}-${var.project}-${var.account}"
}

resource "azurerm_resource_group" "rg" {
  name = "rg-${local.hostbase}${local.unique_append}"
  # az account list-locations, yields list containing UK South
  location = "uksouth"
}

# create a single VM to push logs
resource "azurerm_virtual_network" "default" {
  name                = "default-network-${local.hostbase}${local.unique_append}"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "intnet" {
  name                 = "internal-subnet-${local.hostbase}${local.unique_append}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.default.name}"
  address_prefix       = "${var.subnet_prepend}.0/24"
}

resource "azurerm_network_security_group" "nsg_public" {
  name = "nsgpub-${local.hostbase}${local.unique_append}"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  # port 22 needed for initial access to machine before alternative port opened
  security_rule {
    name = "SSH"
    priority = 1001
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }

  # bastion may field SSH traffic on non-standard port
  security_rule {
    name = "SSH-nonstd-port"
    priority = 1002
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "${var.ssh_additional_port}"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }

  tags = {
    name = "nsgpub-${local.hostbase}${local.unique_append}"
    project = "${var.project}"
    account = "${var.account}"
    environment = "${terraform.workspace}"
  }
}

resource "azurerm_network_security_group" "nsg_private" {
  name = "nsgpriv-${local.hostbase}${local.unique_append}"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  # only allow network access from within the subnet
  # - SSH
  security_rule {
    name = "SSH"
    priority = 1001
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "${azurerm_subnet.intnet.address_prefix}"
    destination_address_prefix = "${azurerm_subnet.intnet.address_prefix}"
  }

  # - Puppet
  security_rule {
    name = "puppet"
    priority = 1002
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "8140"
    source_address_prefix = "${azurerm_subnet.intnet.address_prefix}"
    destination_address_prefix = "${azurerm_subnet.intnet.address_prefix}"
  }

  tags = {
    name = "nsgpriv-${local.hostbase}"
    project = "${var.project}"
    account = "${var.account}"
    environment = "${terraform.workspace}"
  }
}

# bastion using generic module
module "bastion" {
  source = "../shared/create-azure-vm"
  project = "${var.project}"
  account = "${var.account}"
  hostname = "bastion-az-teach${local.unique_append}"
  admin_user = "${var.admin_user}"
  public_key_path = "${var.public_key_path}"
  subnet_id = "${azurerm_subnet.intnet.id}"
  nsg_id = "${azurerm_network_security_group.nsg_public.id}"
  resource_group_location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  puppet_environment = "${var.puppet_environment}"
  # no static private IP
  # bastion-specific additions
  public_ip_address = "${azurerm_public_ip.pubipbst.ip_address}"
  public_ip_address_id = "${azurerm_public_ip.pubipbst.id}"
  ssh_additional_port = "${var.ssh_additional_port}"
  bastion_public_ip = "${azurerm_public_ip.pubipbst.ip_address}"
}
resource "azurerm_public_ip" "pubipbst" {
  name                         = "pubip-bastion-${local.hostbase}${local.unique_append}"
  location                     = "${azurerm_resource_group.rg.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  allocation_method = "Static"
  # public_ip_address_allocation now known as allocation_method
  tags = {
    name = "pubip-bastion-${local.hostbase}${local.unique_append}"
    project = "${var.project}"
    account = "${var.account}"
    environment = "${terraform.workspace}"
  }
}
output "host_bastion_vm_name" {
  value = "${module.bastion.vm_name}"
}
output "host_bastion_public_IP" {
  value = "${module.bastion.public_ip}"
}
output "host_bastion_SSH_command" {
  value = "ssh -A -p ${var.ssh_additional_port} ${var.admin_user}@${module.bastion.public_ip}"
}
output "host_bastion_admin_password" {
  value = "${module.bastion.admin_password}"
}
