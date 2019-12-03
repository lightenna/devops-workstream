#
# create-do-vm-puppetmastered
# OS support: CentOS, Ubuntu
#

# default provider configured in root (upstream) module

locals {
  # STANDARD (puppetmastered, v1.6)
  root_directory = "/root"
  home_directory = var.admin_user == "root" ? "/root" : "/home/${var.admin_user}"
  puppet_exec = "/opt/puppetlabs/bin/puppet"
  puppet_server_exec = "/opt/puppetlabs/bin/puppetserver"
  puppet_run = "${local.puppet_exec} agent -t"
  setup_ssh_additional_port = "sudo /usr/sbin/semanage port -m -t ssh_port_t -p tcp ${var.ssh_additional_port} ; sudo sed -i 's/\\#Port 22/Port 22\\nPort ${var.ssh_additional_port}/g' /etc/ssh/sshd_config ; sudo service sshd restart"
  real_bastion_user = var.bastion_user == "" ? "${var.admin_user}" : "${var.bastion_user}"
  # /STANDARD (puppetmastered, v1.6), custom variables
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
  # STANDARD (puppetmastered, v1.6)
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
      "sudo ${var.pkgman} -y install deltarpm",
      # install basic utilities
      "sudo ${var.pkgman} -y install wget curl unzip htop",
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
  # copy puppet.conf file across to temporary location
  provisioner "file" {
    destination = "/tmp/puppet-additions.conf"
    content = data.template_file.puppet_conf.rendered
  }
  # run puppet agent to generate cert request to puppetmaster
  provisioner "remote-exec" {
    inline = [
      # move puppet.conf into position (as root) to set up puppet agent to point to puppetmaster
      "sudo mv /tmp/puppet-additions.conf /etc/puppetlabs/puppet/puppet.conf",
      # run puppet to create (as yet) unsigned key, ignore errors
      "sudo ${local.puppet_exec} agent -dvt > cert_req_puppet_agent.out 2>&1 || true",
    ]
  }
  # sign cert request locally (on puppetmaster, as root)
  provisioner "local-exec" {
    command = "sudo ${local.puppet_server_exec} ca sign --certname ${var.hostname}.${var.host_domain}"
  }
  # run puppet agent
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
  # when destroying this resource, clean the old certs off the puppet master
  provisioner "local-exec" {
    command = "sudo ${local.puppet_server_exec} ca clean --certname ${var.hostname}.${var.host_domain}; sudo ${local.puppet_exec} node deactivate ${var.hostname}.${var.host_domain}"
    on_failure = continue
    when = destroy
  }
  # /STANDARD (puppetmastered, v1.6)
}

# render a local template file for puppet.conf
data "template_file" "puppet_conf" {
  template = file("${path.module}/templates/puppet.conf.tpl")
  vars = {
    puppet_environment = var.puppet_environment
    puppet_master_fqdn = var.puppet_master_fqdn
    puppet_certname = "${var.hostname}.${var.host_domain}"
  }
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
