
# find a reference to our Key Vault (provisioned in another module)
data "azurerm_key_vault" "kv" {
  name = "kv-${var.project_akv}-${local.unique_append}"
  resource_group_name = "rg-${var.project_akv}-${local.unique_append}"
}
