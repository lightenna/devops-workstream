#
# create-vsphere-vm-puppetmastered
# OS support: CentOS
#

# default provider configured in root (upstream) module

locals {
  # STANDARD (puppetmastered, v2.0)
  puppet_exec = "/opt/puppetlabs/bin/puppet"
  puppet_server_exec = "/opt/puppetlabs/bin/puppetserver"
  puppet_run = "${local.puppet_exec} agent -t"
  real_bastion_user = var.bastion_user == "" ? var.admin_user : var.bastion_user
  # /STANDARD (puppetmastered), custom variables
}

#
# Data sources
#
data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.host_os_image
  datacenter_id = data.vsphere_datacenter.dc.id
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

#
# Resources
#
resource "vsphere_virtual_machine" "vm" {
  connection {
    host = self.clone[0].customize[0].network_interface[0].ipv4_address
    user = self.extra_config.admin_user
  }
  name             = var.hostname
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus               = var.vsphere_cpu
  num_cores_per_socket   = var.vsphere_num_cores_per_socket == "" ? var.vsphere_cpu : var.vsphere_num_cores_per_socket
  cpu_hot_add_enabled    = var.vsphere_cpu_hot_add_enabled
  memory                 = var.vsphere_ram
  memory_hot_add_enabled = var.vsphere_memory_hot_add_enabled
  guest_id               = data.vsphere_virtual_machine.template.guest_id

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "${var.hostname}.vmdk"
    size             = data.vsphere_virtual_machine.template.disks[0].size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks[0].eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks[0].thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    linked_clone  = var.vsphere_linked_clone

    customize {
      timeout = var.vsphere_customize_timeout

      linux_options {
        host_name = lower(var.hostname)
        domain    = var.host_domain
      }

      network_interface {
        ipv4_address = var.private_ip_address
        ipv4_netmask = var.vsphere_netmask
      }

      ipv4_gateway    = var.vsphere_gateway
      dns_server_list = [var.vsphere_dns]
    }
  }

  extra_config = {
    admin_user = var.admin_user
    puppet_exec = local.puppet_exec
    puppet_server_exec = local.puppet_server_exec
  }

  #
  # STANDARD (puppetmastered, v2.0)
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
      puppet_certname: "${lower(var.hostname)}.${var.host_domain}"
    })
  }
  provisioner "remote-exec" {
    inline = [templatefile("../../shared/create-x-vm-shared/templates/puppetmastered_certreq.sh.tmpl", {
      host_specific_commands: var.host_specific_commands,
      pkgman: var.pkgman,
      hostname: lower(var.hostname),
      host_domain: var.host_domain,
      ssh_additional_port: var.ssh_additional_port,
      admin_user: var.admin_user,
      admin_password: random_string.admin_password.result,
      puppet_exec: local.puppet_exec,
    })]
  }
  # sign cert request locally (on puppetmaster, as root)
  provisioner "local-exec" {
    command = "sudo ${local.puppet_server_exec} ca sign --certname ${lower(var.hostname)}.${var.host_domain}"
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
  # /STANDARD (puppetmastered, v2.0)
  # when destroying this resource, clean the old certs off the puppet master
  provisioner "local-exec" {
    command = "sudo ${self.extra_config.puppet_server_exec} ca clean --certname ${self.clone[0].customize[0].linux_options[0].host_name}.${self.clone[0].customize[0].linux_options[0].domain}; sudo ${self.extra_config.puppet_exec} node deactivate ${self.clone[0].customize[0].linux_options[0].host_name}.${self.clone[0].customize[0].linux_options[0].domain}"
    on_failure = continue
    when = destroy
  }
}

