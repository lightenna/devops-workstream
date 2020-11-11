
output "host1_ssh" {
  value = "ssh -A -p 22 ${module.vm1.admin_user}@${module.vm1.ip}"
}

output "keysec_output" {
  value = data.azurerm_key_vault_secret.keysec.value
}
