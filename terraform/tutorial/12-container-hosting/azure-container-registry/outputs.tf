output "login_command" {
  value = "docker login -u '${azurerm_key_vault_secret.adminuser.value}' --password '${azurerm_key_vault_secret.adminpass.value}' ${azurerm_container_registry.acr.login_server}"
}

output "logout_command" {
  value = "docker logout ${azurerm_container_registry.acr.login_server}"
}

