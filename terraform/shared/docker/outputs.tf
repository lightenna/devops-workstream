#
# Output variables for other modules to use
#

# private IP of the docker host
output "instantiated_host_private_ip" {
  value = aws_instance.docker_host.private_ip
}

output "instantiated_host_ssh_command" {
  value = "ssh -A -o StrictHostKeyChecking=no -o ProxyCommand='ssh -o StrictHostKeyChecking=no -W %h:%p centos@${var.bastion_host}' centos@${aws_instance.docker_host.private_ip}"
}

output "docker_container_list_command" {
  value = "sudo -u dockeruser docker container ls"
}

