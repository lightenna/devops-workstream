
# find a reference to our Key Vault (provisioned in another module)
data "azurerm_key_vault" "kv" {
  name = "kv-${var.project_akv}-${local.unique_append}"
  resource_group_name = "rg-${var.project_akv}-${local.unique_append}"
}

# store admin username and password in Key Vault
resource "azurerm_key_vault_secret" "adminpass" {
  name = "admin-password"
  value = azurerm_container_registry.acr.admin_password
  key_vault_id = data.azurerm_key_vault.kv.id
  tags = {
    name = "admin-password"
    project = var.project
    environment = terraform.workspace
  }
}

resource "azurerm_key_vault_secret" "adminuser" {
  name = "admin-username"
  value = azurerm_container_registry.acr.admin_username
  key_vault_id = data.azurerm_key_vault.kv.id
  tags = {
    name = "admin-username"
    project = var.project
    environment = terraform.workspace
  }
}
