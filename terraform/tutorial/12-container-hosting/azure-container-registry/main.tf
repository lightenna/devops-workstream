#
# Create a container hosting environment
# Cloud: Azure

locals {
  # use a unique ID for all resources based on a random string unless one is specified
  unique_append = var.unique_id == "" ? random_string.unique_key.result : var.unique_id
  hostbase = "${var.project}-${local.unique_append}"
}

resource "random_string" "unique_key" {
  length = 8
  upper = false
  special = false
}

# resource group name uses derived (local) unique_append, but region comes from external, default in variables.tf
resource "azurerm_resource_group" "rg" {
  name = "rg${local.unique_append}"
  location = var.region
}

# ACR name can only contain alpha-numeric characters
resource "azurerm_container_registry" "acr" {
  name                     = "acr8conhost8${var.unique_id}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = "Premium"
  admin_enabled            = true
}

