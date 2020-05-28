#
# Create virtual network using a module
# Cloud: Azure

# store state locally for shared IAC to avoid bootstrapping
terraform {
  backend "local" {
  }
}

provider "azurerm" {
  features {}
}

module "net" {
  source    = "./azure-network"
  unique_id = var.unique_id
  region    = var.region
}

