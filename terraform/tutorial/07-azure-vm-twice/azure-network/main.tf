#
# Create virtual network
# Cloud: Azure

# store state locally for shared IAC to avoid bootstrapping
terraform {
  backend "local" {
  }
}

provider "azurerm" {
  features {}
}

# create a virtual network, subnet and security group to define access policy
resource "azurerm_virtual_network" "default" {
  name                = "default-network${var.unique_append}"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.resource_group_location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_subnet" "intnet" {
  name                 = "internal-subnet${var.unique_append}"
  resource_group_name  = "${var.resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.default.name}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_network_security_group" "nsg_public" {
  name                = "nsgpub${var.unique_append}"
  location            = "${var.resource_group_location}"
  resource_group_name = "${var.resource_group_name}"

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
    name = "nsgpub${var.unique_append}"
    environment = "${terraform.workspace}"
  }
}

