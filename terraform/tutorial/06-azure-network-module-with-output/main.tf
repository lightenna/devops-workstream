#
# Create virtual network using a module
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
  special = false
}

# resource group name uses derived (local) unique_append, but region comes from external, default in variables.tf
resource "azurerm_resource_group" "rg" {
  name     = "rg${local.unique_append}"
  location = "${var.region}"
}

module "net" {
  source = "./azure-network"
  unique_append = "${local.unique_append}"
  region = "${var.region}"
}

resource "azurerm_public_ip" "pubipbst" {
  name                         = "pubip-${local.unique_append}"
  location                     = "${azurerm_resource_group.rg.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  allocation_method = "Static"
  # public_ip_address_allocation now known as allocation_method
  tags = {
    name = "pubip-${local.unique_append}"
    environment = "${terraform.workspace}"
  }
}

# @todo create VM