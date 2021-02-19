
resource "random_string" "secvalue" {
  length = 24
  special = true
  # explicitly use the full list of special characters
  # override_special = "!@#$%&*()-_=+[]{}<>:?"
  # explicitly use a narrow set of special characters
  override_special = "!@#$%*_"
}

#
# create secrets
#

resource "azurerm_key_vault_secret" "temppass" {
  name = "temp-password"
  value = random_string.secvalue.result
  key_vault_id = azurerm_key_vault.mkv.id
  tags = {
    name = "temp-password"
    project = var.project
    environment = terraform.workspace
  }
}
