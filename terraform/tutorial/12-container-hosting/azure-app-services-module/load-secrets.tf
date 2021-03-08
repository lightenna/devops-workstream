
data "azurerm_key_vault_secret" "adminpass" {
  name = "admin-password"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "adminuser" {
  name = "admin-username"
  key_vault_id = data.azurerm_key_vault.kv.id
}

