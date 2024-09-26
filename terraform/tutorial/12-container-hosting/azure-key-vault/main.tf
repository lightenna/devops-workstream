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
  name = "rg-${local.hostbase}"
  location = var.region
}

# get IP address of provisioning machine
data "http" "provisip" {
  url = "http://ipv4.icanhazip.com"
}

# read the current config to get tenant and service principal
data "azurerm_client_config" "current" {}

# create an Azure Key Vault for storing secrets
resource "azurerm_key_vault" "mkv" {
  name = "kv-${local.hostbase}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  enabled_for_deployment = true
  enabled_for_template_deployment = false
  tenant_id = data.azurerm_client_config.current.tenant_id
  # standard means RSA 2048-bit keys and no HSM, 2.3p/10,000 operations
  sku_name = "standard"
  # set up access control list
  network_acls {
    default_action = "Deny"
    bypass = "AzureServices"
    # should really only grant access to limited set of hosts
    ip_rules = [
      "0.0.0.0/0"]
    # grant access to starter if set up
    virtual_network_subnet_ids = []
  }
  # inline access policies to make deleting easier
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    # all permissions from https://www.terraform.io/docs/providers/azurerm/r/key_vault_access_policy.html
    key_permissions = [
      "Backup",
      "Create",
      "Decrypt",
      "Delete",
      "Encrypt",
      "Get",
      "Import",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Sign",
      "UnwrapKey",
      "Update",
      "Verify",
      "WrapKey"]
    secret_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set"]
    certificate_permissions = [
      "Backup",
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "Purge",
      "Recover",
      "Restore",
      "SetIssuers",
      "Update"]
    storage_permissions = [
      "Get",
      "List",
      "Delete"]
  }
  tags = {
    name = "kv-${local.hostbase}"
    project = var.project
    environment = terraform.workspace
  }
}
