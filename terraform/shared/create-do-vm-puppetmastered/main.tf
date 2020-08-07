#
# create-do-vm-puppetmastered
# OS support: CentOS, Ubuntu
#

# default provider configured in root (upstream) module

locals {
  # STANDARD (puppetmastered, v1.9)
  puppet_exec = "/opt/puppetlabs/bin/puppet"
  puppet_server_exec = "/opt/puppetlabs/bin/puppetserver"
  puppet_run = "${local.puppet_exec} agent -t"
  real_bastion_user = var.bastion_user == "" ? var.admin_user : var.bastion_user
  # /STANDARD (puppetmastered), custom variables
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
  # STANDARD (puppetmastered, v1.9)
  #
  # upload facts
  provisioner "file" {
    destination = "/tmp/puppet-facts.yaml"
    content = templatefile("../../shared/create-x-vm-shared/templates/ext-facts.yaml.tmpl", {
      facts: var.facts
    })
  }
  # upload puppet.conf, install puppet, kick off cert_request, kick off cert_request
  provisioner "file" {
    destination = "/tmp/puppet-additions.conf"
    content = templatefile("../../shared/create-x-vm-shared/templates/puppet.conf.tmpl", {
      puppet_environment: var.puppet_environment
      puppet_master_fqdn: var.puppet_master_fqdn
      puppet_certname: "${var.hostname}.${var.host_domain}"
    })
  }
  provisioner "remote-exec" {
    inline = [templatefile("../../shared/create-x-vm-shared/templates/puppetmastered_certreq.sh.tmpl", {
      host_specific_commands: var.host_specific_commands,
      pkgman: var.pkgman,
      hostname: var.hostname,
      host_domain: var.host_domain,
      ssh_additional_port: var.ssh_additional_port,
      admin_user: var.admin_user,
      admin_password: random_string.admin_password.result,
      puppet_exec: local.puppet_exec,
    })]
  }
  # sign cert request locally (on puppetmaster, as root)
  provisioner "local-exec" {
    command = "sudo ${local.puppet_server_exec} ca sign --certname ${var.hostname}.${var.host_domain}"
  }
  # run puppet agent
  provisioner "remote-exec" {
    inline = [templatefile("../../shared/create-x-vm-shared/templates/puppet_run.sh.tmpl", {
      puppet_mode: var.puppet_mode,
      puppet_run: local.puppet_run,
      puppet_sleeptime: var.puppet_sleeptime,
      admin_user: var.admin_user,
    })]
  }
  # when destroying this resource, clean the old certs off the puppet master
  provisioner "local-exec" {
    command = "sudo ${local.puppet_server_exec} ca clean --certname ${var.hostname}.${var.host_domain}; sudo ${local.puppet_exec} node deactivate ${var.hostname}.${var.host_domain}"
    on_failure = continue
    when = destroy
  }
  # /STANDARD (puppetmastered, v1.9)
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
