output "vault_URI" {
  value = azurerm_key_vault.mkv.vault_uri
}

output "vault_secret_adminpass" {
  sensitive = true
  value = "${azurerm_key_vault_secret.temppass.name} (${length(azurerm_key_vault_secret.temppass.value)} bytes)"
}
