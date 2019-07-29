#
# Create resource group
# Cloud: Azure

# store state locally for shared IAC to avoid bootstrapping
terraform {
  backend "local" {
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.unique_id}"
  location = "uksouth"
}
