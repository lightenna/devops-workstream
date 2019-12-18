#
# Create virtual network
# Cloud: Azure

# store state locally for shared IAC to avoid bootstrapping
terraform {
  backend "local" {
  }
}

locals {
  # use a unique ID for all resources based on a random string unless one is specified
  unique_append = "${ var.unique_id == "" ? "-${random_string.unique_key.result}" : "-${var.unique_id}"}"
}

resource "random_string" "unique_key" {
  length = 8
  upper = false
  special = false
}

# resource group name uses derived (local) unique_append, but region comes from external, default in variables.tf
resource "azurerm_resource_group" "rg" {
  name     = "rg${local.unique_append}"
  location = "${var.region}"
}

# create a virtual network, subnet and security group to define access policy
resource "azurerm_virtual_network" "default" {
  name                = "default-network${local.unique_append}"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "intnet" {
  name                 = "internal-subnet${local.unique_append}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.default.name}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_network_security_group" "nsg_public" {
  name                = "nsgpub${local.unique_append}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  # allow inbound SSH on port 22
  security_rule {
    name                   = "SSH"
    priority               = 1001
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = "22"
    source_address_prefix  = "*"
    destination_address_prefix = "*"
  }

  tags = {
    name = "nsgpub${local.unique_append}"
    environment = "${terraform.workspace}"
  }
}
