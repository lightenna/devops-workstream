#
# create-do-vm-puppetmless
# OS support: CentOS, Ubuntu
#

# default provider configured in root (upstream) module

locals {
  # STANDARD (puppetmless, v1.6)
  root_directory = "/root"
  home_directory = var.admin_user == "root" ? "/root" : "/home/${var.admin_user}"
  puppet_target_repodir = "/etc/puppetlabs/puppetmless"
  puppet_source = "${path.module}/../../../puppet"
  puppet_run = "/opt/puppetlabs/bin/puppet apply -t --hiera_config=${local.puppet_target_repodir}/environments/${var.puppet_environment}/hiera.yaml --modulepath=${local.puppet_target_repodir}/modules:${local.puppet_target_repodir}/environments/shared/modules:${local.puppet_target_repodir}/environments/${var.puppet_environment}/modules ${local.puppet_target_repodir}/environments/${var.puppet_environment}/manifests/${var.puppet_manifest_name}"
  setup_ssh_additional_port = "sudo /usr/sbin/semanage port -m -t ssh_port_t -p tcp ${var.ssh_additional_port} ; sudo sed -i 's/\\#Port 22/Port 22\\nPort ${var.ssh_additional_port}/g' /etc/ssh/sshd_config ; sudo service sshd restart"
  real_bastion_user = var.bastion_user == "" ? "${var.admin_user}" : "${var.bastion_user}"
  # /STANDARD (puppetmless, v1.6), custom variables
  real_bastion_public_ip = var.bastion_public_ip == "" ? digitalocean_droplet.host.ipv4_address : "${var.bastion_public_ip}"
}

# admin_password must be between 6-72 characters long and must satisfy at least 3 of password complexity requirements from the following: 1. Contains an uppercase character 2. Contains a lowercase character 3. Contains a numeric digit 4. Contains a special character
resource "random_string" "admin_password" {
  length = 12
  special = true
  # short list of special characters so double-click select works on password
  override_special = "-_"
  min_lower = 1
  min_upper = 1
  min_numeric = 1
  min_special = 1
}

# find the (already created) DO key
data "digitalocean_ssh_key" "singlet" {
  name = var.ssh_key_name
}

# create and puppet a host
resource "digitalocean_droplet" "host" {
  connection {
    type = "ssh"
    user = var.admin_user
    # duplicate real_bastion_public_ip to avoid cycle
    bastion_host = var.bastion_public_ip == "" ? self.ipv4_address : "${var.bastion_public_ip}"
    bastion_user = local.real_bastion_user
    bastion_port = var.bastion_ssh_port
    host = self.ipv4_address
  }
  name   = "${var.hostname}.${var.host_domain}"
  image  = var.host_os_image
  region = var.region
  size   = var.host_size
  ipv6 = false
  private_networking = true
  # install free monitoring agent
  monitoring = true
  ssh_keys = [data.digitalocean_ssh_key.singlet.id]
  tags = split(";", var.host_tags)
  #
  # STANDARD (puppetmless, v1.6)
  #
  # wait for cloud provider to finish install its stuff, otherwise yum/dpkg collide [standard]
  provisioner "remote-exec" {
    inline = ["sleep 60"]
  }
  # run any host-specific commands [standard]
  provisioner "remote-exec" {
    inline = split(";", var.host_specific_commands)
  }
  # run install script to build host [standard]
  provisioner "remote-exec" {
    inline = [
      # deltarpm to reduce package manager work
      "sudo ${var.pkgman} -y install deltarpm wget curl unzip htop",
      # install semanage for SELinux
      "sudo ${var.pkgman} -y install policycoreutils-python",
      "sudo ${var.pkgman} -y update",
      "sudo ${var.pkgman} -y install puppet-agent",
      # set the hostname
      "sudo hostnamectl set-hostname ${var.hostname}.${var.host_domain}",
      # make SSH available on additional port, only if set
      var.ssh_additional_port == "22" ? "echo no_additional_port" : local.setup_ssh_additional_port,
      # add admin user to wheel group to allow passworded sudo (redundant for root)
      "sudo usermod -aG wheel ${var.admin_user}",
      # set the admin user's password
      "sudo bash -c \"echo -e '${random_string.admin_password.result}\n${random_string.admin_password.result}' | passwd ${var.admin_user}\"",
    ]
  }
  # upload puppet manifests [standard]
  provisioner "file" {
    source = local.puppet_source
    # transfer to intermediary folder
    destination = "/tmp/puppet-additions"
    # can't go straight to final destination because user doesn't have access
    # and "file" provisioners have no sudo escalation
  }
  # merge puppetmless manifests into target puppet folder [standard]
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p ${local.puppet_target_repodir}/",
      "sudo mv /tmp/puppet-additions/* ${local.puppet_target_repodir}/",
      # give admin user perms to allow post-terraform rsync
      "sudo chown -R ${var.admin_user}:${var.admin_user} ${local.puppet_target_repodir}/",
    ]
  }
  # run puppet apply
  provisioner "remote-exec" {
    inline = [
      # blocking: run puppet using uploaded modules, output to console only
      # - currently fails because CSF blocks the run, which then kills the process
      var.puppet_mode == "blocking" ? "sudo bash -c '(${local.puppet_run} 2>&1; exit 0)'; exit 0" : "echo 'Different mode selected'",
      # soft-blocking: run puppet; wait a few seconds, then tail the run until complete
      # - currently does not show the puppet run
      var.puppet_mode == "soft-blocking" ? "sudo bash -c 'nohup ${local.puppet_run} > ${local.root_directory}/puppet_agent.out 2>&1 &' && sleep 6 ; exit 0" : "echo 'Different mode selected'",
      var.puppet_mode == "soft-blocking" ? "sudo bash -c 'tail -f -n100 ${local.root_directory}/puppet_agent.out | while read LOGLINE; do echo \"$${LOGLINE}\"; [[ \"$${LOGLINE}\" == *\"Notice: Applied catalog in\"* ]] && pkill -P $$ tail; done'" : "echo 'Different mode selected'",
      # fire-and-forget: run puppet; wait a few seconds, then tail progress to show start, return
      # + works, but cannot do anything downstream of puppet run
      var.puppet_mode == "fire-and-forget" ? "sudo bash -c 'nohup ${local.puppet_run} > ${local.root_directory}/puppet_agent.out 2>&1 &'" : "echo 'Different mode selected'",
      var.puppet_mode == "fire-and-forget" ? "sleep ${var.puppet_sleeptime}" : "echo 'Different mode selected'",
      var.puppet_mode == "fire-and-forget" ? "sudo bash -c 'tail -n10000 ${local.root_directory}/puppet_agent.out'" : "echo 'Different mode selected'",
    ]
  }
  # /STANDARD (puppetmless, v1.6)
}

data "digitalocean_domain" "domain" {
  name = var.host_domain
  count = (var.create_dns_entry == "yes" ? 1 : 0)
}

# create an A record for easy access
resource "digitalocean_record" "a_record" {
  domain = data.digitalocean_domain.domain.0.name
  type   = "A"
  name   = var.hostname
  value  = digitalocean_droplet.host.ipv4_address
  # set short TTL
  ttl    = "300"
  count = (var.create_dns_entry == "yes" ? 1 : 0)
}
