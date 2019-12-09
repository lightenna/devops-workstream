
# bastion using generic module
output "host_bastion_SSH_command" {
  value = "ssh -A -p ${var.ssh_additional_port} ${module.bastion.admin_user}@${module.bastion.public_ip}"
}

output "host_bastion_admin_password" {
  value = module.bastion.admin_password
}

output "host_bastion_re-send_all_puppet_scripts" {
  value = "${module.bastion.resend_puppet_scripts}\r\n"
}

output "host_bastion_re-puppet_command_on_host" {
  value = "${module.bastion.repuppet_command}\r\n"
}

# puppetmaster host using generic module
output "host_master_SSH_command" {
  value = "ssh -A -p ${var.ssh_additional_port} ${module.master.admin_user}@${module.master.public_ip}"
}

output "host_master_admin_password" {
  value = module.master.admin_password
}

output "host_master_re-send_all_puppet_scripts" {
  value = "${module.master.resend_puppet_scripts}\r\n"
}

output "host_master_re-puppet_command_on_host" {
  value = "${module.master.repuppet_command}\r\n"
}

