output "admin_user" {
  value = var.admin_user
}
output "admin_password" {
  value = random_string.admin_password.result
}
output "private_ip" {
  value = oci_core_instance.instance[0].private_ip
}
output "public_ip" {
  value = oci_core_instance.instance[0].public_ip
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
  value = "ssh -A -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -A -p ${var.bastion_ssh_port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ${var.admin_user}@${var.bastion_public_ip}' ${var.admin_user}@${oci_core_instance.instance[0].private_ip}"
}
output "ssh_additional_port" {
  value = var.ssh_additional_port
}
output "repuppet_command" {
  # note live output streamed using tail but never completes; needs Ctrl+C to exit from tail -f
  value = "sudo bash -c '${local.puppet_run} > /root/puppet_apply.out & 2>&1 ; tail -f -n1000 /root/puppet_apply.out'"
}
output "resend_puppet_scripts" {
  value = "n/a"
}

