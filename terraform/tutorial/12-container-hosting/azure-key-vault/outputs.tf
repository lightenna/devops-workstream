output "vault_URI" {
  value = azurerm_key_vault.mkv.vault_uri
}

output "vault_secret_adminpass" {
  value = "${azurerm_key_vault_secret.adminpass.name} (${length(azurerm_key_vault_secret.adminpass.value)} bytes)"
}
