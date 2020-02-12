#
# create-do-vm-puppetmless
# OS support: CentOS, Ubuntu
#

# default provider configured in root (upstream) module

locals {
  # STANDARD (puppetmless, v1.6)
  home_directory = var.admin_user == "root" ? "/root" : "/home/${var.admin_user}"
  puppet_target_repodir = "/etc/puppetlabs/puppetmless"
  puppet_source = "${path.module}/../../../puppet"
  puppet_run = "/opt/puppetlabs/bin/puppet apply -t --hiera_config=${local.puppet_target_repodir}/environments/${var.puppet_environment}/hiera.yaml --modulepath=${local.puppet_target_repodir}/modules:${local.puppet_target_repodir}/environments/shared/modules:${local.puppet_target_repodir}/environments/${var.puppet_environment}/modules ${local.puppet_target_repodir}/environments/${var.puppet_environment}/manifests/${var.puppet_manifest_name}"
  setup_ssh_additional_port = "sudo /usr/sbin/semanage port -m -t ssh_port_t -p tcp ${var.ssh_additional_port} ; sudo sed -i 's/\\#Port 22/Port 22\\nPort ${var.ssh_additional_port}/g' /etc/ssh/sshd_config ; sudo service sshd restart"
  real_bastion_user = var.bastion_user == "" ? var.admin_user : var.bastion_user
  # /STANDARD (puppetmless, v1.6), custom variables
  real_bastion_public_ip = var.bastion_public_ip == "" ? digitalocean_droplet.host.ipv4_address : var.bastion_public_ip
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
    bastion_host = var.bastion_public_ip == "" ? self.ipv4_address : var.bastion_public_ip
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
  # STANDARD (puppetmless, v1.8)
  #
  # upload facts
  provisioner "file" {
    destination = "/tmp/puppet-facts.yaml"
    content = templatefile("../../shared/create-x-vm-shared/templates/ext-facts.yaml.tmpl", {
      facts: var.facts
    })
  }
  # upload puppet manifests and puppet
  provisioner "file" {
    source = local.puppet_source
    # transfer to intermediary folder
    destination = "/tmp/puppet-additions"
    # can't go straight to final destination because user doesn't have access
    # and "file" provisioners have no sudo escalation
  }
  provisioner "remote-exec" {
    inline = [
      templatefile("../../shared/create-x-vm-shared/templates/puppetmless.sh.tmpl", {
        host_specific_commands: var.host_specific_commands,
        pkgman: var.pkgman,
        hostname: var.hostname,
        host_domain: var.host_domain,
        ssh_additional_port: var.ssh_additional_port,
        admin_user: var.admin_user,
        admin_password: random_string.admin_password.result,
        puppet_target_repodir: local.puppet_target_repodir,
      }),
      templatefile("../../shared/create-x-vm-shared/templates/puppet_run.sh.tmpl", {
        puppet_mode: var.puppet_mode,
        puppet_run: local.puppet_run,
        puppet_sleeptime: var.puppet_sleeptime,
      })
    ]
  }
  # /STANDARD (puppetmless, v1.8)
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
