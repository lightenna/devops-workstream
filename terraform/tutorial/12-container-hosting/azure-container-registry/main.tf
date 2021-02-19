#
# Create a container hosting environment
# Cloud: Azure

locals {
  # use a unique ID for all resources based on a random string unless one is specified
  unique_append = var.unique_id == "" ? "-${random_string.unique_key.result}" : "-${var.unique_id}"
  admin_user = "rootlike"
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

# get IP address of provisioning machine
data "http" "provisip" {
  url = "http://ipv4.icanhazip.com"
}

