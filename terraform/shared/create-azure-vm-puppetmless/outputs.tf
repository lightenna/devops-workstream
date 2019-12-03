output "admin_user" {
  value = var.admin_user
}
output "admin_password" {
  value = random_string.admin_password.result
}
output "private_ip" {
  value = azurerm_network_interface.stnic.private_ip_address
}
output "public_ip" {
  # note: this is a pass-through, because the public IP address is created outside of this module
  value = var.public_ip_address
}
output "bastion_host" {
  value = var.bastion_public_ip
}
output "bastion_port" {
  value = var.bastion_ssh_port
}
output "bastion_user" {
  value = local.real_bastion_user
}
output "host_fqdn" {
  value = "${var.hostname}.${var.host_domain}"
}
output "ssh_command" {
  # disable host checking and store the received key in /dev/null to avoid false 'man-in-the-middle' warnings
  value = "ssh -A -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -A -p ${var.bastion_ssh_port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ${var.admin_user}@${var.bastion_public_ip}' ${var.admin_user}@${azurerm_network_interface.stnic.private_ip_address}"
}
output "ssh_additional_port" {
  value = var.ssh_additional_port
}
output "repuppet_command" {
  # note live output streamed using tail but never completes; needs Ctrl+C to exit from tail -f
  value = "sudo bash -c '${local.puppet_run} > ${local.root_directory}/puppet_apply.out & 2>&1 ; tail -f -n1000 ${local.root_directory}/puppet_apply.out'"
}
output "resend_puppet_scripts" {
  # include puppet/* to avoid getting hidden folders (like .tmp or .rb)
  value = "rsync -av --delete --rsh 'ssh -A  -p ${var.ssh_additional_port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${var.admin_user}@${var.bastion_public_ip} ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' ${path.cwd}/${local.puppet_source}/* ${var.admin_user}@${azurerm_network_interface.stnic.private_ip_address}:${local.puppet_target_repodir}/"
}
output "host_principal_id" {
  value = azurerm_virtual_machine.host.identity.0.principal_id
}
