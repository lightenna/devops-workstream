output "admin_user" {
  value = var.admin_user
}
output "admin_password" {
  value = random_string.admin_password.result
}
output "private_ip" {
  value = digitalocean_droplet.host.ipv4_address_private
}
output "public_ip" {
  value = digitalocean_droplet.host.ipv4_address
}
output "bastion_host" {
  value = local.real_bastion_public_ip
}
output "bastion_port" {
  value = var.bastion_ssh_port
}
output "bastion_user" {
  value = local.real_bastion_user
}
output "host_fqdn" {
  value = var.create_dns_entry == "yes" ? "${digitalocean_record.a_record.0.name}.${digitalocean_record.a_record.0.domain}" : "no-dns-entry-created.local"
}
output "host_droplet_id" {
  value = digitalocean_droplet.host.id
}
output "ssh_command" {
  # disable host checking and store the received key in /dev/null to avoid false 'man-in-the-middle' warnings
  value = "ssh -A -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -A -p ${var.bastion_ssh_port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ${local.real_bastion_user}@${local.real_bastion_public_ip}' ${var.admin_user}@${digitalocean_droplet.host.ipv4_address}"
}
output "ssh_additional_port" {
  value = var.ssh_additional_port
}
output "repuppet_command" {
  # note live output streamed using tail but never completes; needs Ctrl+C to exit from tail -f
  value = "sudo bash -c '${local.puppet_run} > ${local.root_directory}/puppet_apply.out & 2>&1 ; tail -f -n1000 ${local.root_directory}/puppet_apply.out'"
}
output "resend_puppet_scripts" {
  value = "n/a"
}
