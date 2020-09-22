#
# azure-secrets
#   requires: none
#   cost estimate: 3p for 10,000 runs
#

locals {
  key_path = "../../../eyaml/keys"
  private_key_fullpath = "${abspath(local.key_path)}/${var.private_key_name}"
  public_key_fullpath = "${abspath(local.key_path)}/${var.public_key_name}"
  # use a unique ID for all resources based on a random string unless one is specified
  unique_append = var.unique_id == "" ? random_string.unique_key.result : var.unique_id
  hostbase = "${var.project}-${local.unique_append}"
}

resource "random_string" "unique_key" {
  length  = 4
  upper = false
  special = false
}

resource "azurerm_resource_group" "rgs" {
  name = "rgs-${local.hostbase}"
  # az account list-locations, yields list containing UK South
  location = "uksouth"
}

# read the current config to get tenant and service principal
data "azurerm_client_config" "current" {}

# create an Azure Key Vault for storing secrets
resource "azurerm_key_vault" "mkv" {
  name = "kv-${local.hostbase}"
  location = azurerm_resource_group.rgs.location
  resource_group_name = azurerm_resource_group.rgs.name
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
  tags = {
    name = "kv-${local.hostbase}"
    project = var.project
    environment = terraform.workspace
  }
}

# grant permission for Terraform user to create/delete/update keys
resource "azurerm_key_vault_access_policy" "perm_tfsp" {
  key_vault_id = azurerm_key_vault.mkv.id
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id
  # all permissions from https://www.terraform.io/docs/providers/azurerm/r/key_vault_access_policy.html
  key_permissions = [
    "backup",
    "create",
    "decrypt",
    "delete",
    "encrypt",
    "get",
    "import",
    "list",
    "purge",
    "recover",
    "restore",
    "sign",
    "unwrapKey",
    "update",
    "verify",
    "wrapKey"]
  secret_permissions = [
    "backup",
    "delete",
    "get",
    "list",
    "purge",
    "recover",
    "restore",
    "set"]
  certificate_permissions = [
    "backup",
    "create",
    "delete",
    "deleteissuers",
    "get",
    "getissuers",
    "import",
    "list",
    "listissuers",
    "managecontacts",
    "manageissuers",
    "purge",
    "recover",
    "restore",
    "setissuers",
    "update"]
  storage_permissions = [
    "get",
    "list",
    "delete"]
}

output "vault_URI" {
  value = azurerm_key_vault.mkv.vault_uri
}

output "generated_cert" {
  value = "${azurerm_key_vault_key.keyex.name} (${azurerm_key_vault_key.keyex.key_size} bytes)"
}

output "uploaded_private_key" {
  value = "${azurerm_key_vault_secret.eyaml_private_key.name} (${length(azurerm_key_vault_secret.eyaml_private_key.value)} bytes)"
}
