#
# Output variables for other modules to use
#

# private IP of the ansible host
output "instantiated_host_private_ip" {
  value = aws_instance.ansible_host.private_ip
}

output "instantiated_host_ssh_command" {
  value = "ssh -A -o StrictHostKeyChecking=no -o ProxyCommand='ssh -o StrictHostKeyChecking=no -W %h:%p centos@${var.bastion_host}' centos@${aws_instance.ansible_host.private_ip}"
}

