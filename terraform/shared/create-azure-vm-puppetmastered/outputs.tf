output "admin_user" {
  value = "${var.admin_user}"
}
output "admin_password" {
  value = "${random_string.admin_password.result}"
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
output "ssh_additional_port" {
  value = "${var.ssh_additional_port}"
}
output "repuppet_command" {
  # note live output streamed using tail but never completes; needs Ctrl+C to exit from tail -f
  value = "sudo bash -c '${local.puppet_agent} > ${local.home_directory}/puppet_apply.out & 2>&1 ; tail -f -n1000 ${local.home_directory}/puppet_apply.out'"
}
output "resend_puppet_scripts" {
  value = "n/a"
}
