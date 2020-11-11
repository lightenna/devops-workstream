
data "azurerm_resource_group" "rg" {
  name = "rgs-sec-example"
}

data "azurerm_key_vault" "kv" {
  name = "kv-sec-example"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_key_vault_secret" "keysec" {
  key_vault_id = data.azurerm_key_vault.kv.id
  name = "kv-secret-refable"
}

