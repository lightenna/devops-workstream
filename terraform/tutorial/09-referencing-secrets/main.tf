
# Note:
# This module requires that tutorial/08-azure-secrets be instantiated in the same subscription
# prior to running `terraform apply` here

locals {
  # use a unique ID for all resources based on a random string unless one is specified
  unique_append = var.unique_id == "" ? random_string.unique_key.result : var.unique_id
}

resource "random_string" "unique_key" {
  length  = 4
  upper = false
  special = false
}

# resource group name uses derived (local) unique_append, but region comes from external, default in variables.tf
resource "azurerm_resource_group" "rg" {
  name     = "rg-vms-${local.unique_append}"
  location = var.region
}

# create network resources
module "net" {
  source        = "./azure-network"
  unique_append = local.unique_append
  region        = var.region

  # pass in shared resource group
  resource_group_location = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
}

# create some VMs
module "vm1" {
  source          = "./azure-virtual-machine"
  unique_append   = local.unique_append
  hostname        = "host1"
  public_key_path = "~/.ssh/id_rsa_devops_simple_key.pub"
  region          = var.region

  # pass in shared resource group
  resource_group_location = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name

  # pass in network IDs based on module output to ensure dependency
  nsg_id    = module.net.nsg_id
  subnet_id = module.net.subnet_id
  admin_password = data.azurerm_key_vault_secret.keysec.value
}
