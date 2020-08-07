#
# Create resource group
# Cloud: Azure

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.unique_id}"
  location = "uksouth"
}

