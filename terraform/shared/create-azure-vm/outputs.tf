output "admin_password" {
  value = "${random_string.admin_password.result}"
}
output "vm_name" {
  value = "${azurerm_virtual_machine.host.name}"
}
output "private_ip" {
  value = "${azurerm_network_interface.stnic.private_ip_address}"
}
output "public_ip" {
  # note: this is only a pass-through, no public IP address is created by this submodule
  value = "${var.public_ip_address}"
}
output "ssh_command" {
  # disable host checking and store the received key in /dev/null to avoid false 'man-in-the-middle' warnings
  value = "ssh -A -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -A -p ${var.bastion_ssh_port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ${var.admin_user}@${var.bastion_public_ip}' ${var.admin_user}@${azurerm_network_interface.stnic.private_ip_address}"
}
output "repuppet_command" {
  # note live output streamed using tail but never completes; needs Ctrl+C to exit from tail -f
  value = "sudo bash -c '${local.puppet_apply} > ${local.home_directory}/puppet_apply.out & 2>&1 ; tail -f -n1000 ${local.home_directory}/puppet_apply.out'"
}
output "resend_puppet_scripts" {
  # include puppet/* to avoid getting hidden folders (like .tmp or .rb)
  value = "rsync -av --delete --rsh 'ssh -A  -p ${var.bastion_ssh_port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${var.admin_user}@${var.bastion_public_ip} ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' ${local.puppet_source_relative}/* ${var.admin_user}@${azurerm_network_interface.stnic.private_ip_address}:${local.puppet_target_repodir}/"
}
