
# find a reference to our Key Vault (provisioned in another module)
data "azurerm_key_vault" "kv" {
  name = "kv-${var.project_akv}-${local.unique_append}"
  resource_group_name = "rg-${var.project_akv}-${local.unique_append}"
}

# tell the Key Vault to grant 'get' access to app_service
resource "azurerm_key_vault_access_policy" "main" {
  key_vault_id       = data.azurerm_key_vault.kv.id
  tenant_id          = azurerm_app_service.service.identity[0].tenant_id
  object_id          = azurerm_app_service.service.identity[0].principal_id
  secret_permissions = ["get"]
}
