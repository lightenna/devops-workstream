#
# create-azure-vm-puppetmastered
# OS support: CentOS
#

# default provider configured in root (upstream) module

locals {
  # STANDARD (puppetmastered, v1.8)
  puppet_exec = "/opt/puppetlabs/bin/puppet"
  puppet_server_exec = "/opt/puppetlabs/bin/puppetserver"
  puppet_run = "${local.puppet_exec} agent -t"
  real_bastion_user = var.bastion_user == "" ? var.admin_user : var.bastion_user
  # /STANDARD (puppetmastered, v1.6), custom variables
  hostbase = "${var.hostname}-${terraform.workspace}-${var.project}-${var.account}"
  setup_log_analytics_workspace = "sudo sh onboard_agent.sh -w ${var.log_analytics_workspace_id} -s ${var.log_analytics_workspace_key}"
  setup_move_laa_files = "sudo mv /tmp/omsagent.conf /etc/opt/microsoft/omsagent/${var.log_analytics_workspace_id}/conf/omsagent.conf && sudo mv /tmp/95-omsagent.conf /etc/rsyslog.d/95-omsagent.conf"
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

resource "azurerm_network_interface" "stnic" {
  name = "stnic-${local.hostbase}"
  location = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name = "ipcfg-stnic-${local.hostbase}"
    subnet_id = var.subnet_id
    private_ip_address = var.private_ip
    private_ip_address_allocation = var.private_ip_address_allocation
    public_ip_address_id = var.public_ip_address_id
  }
  tags = {
    name = "stnic-${local.hostbase}"
    project = var.project
    account = var.account
    environment = terraform.workspace
  }
}

# associate subnet with NSG
resource "azurerm_subnet_network_security_group_association" "nsgsubnet" {
  subnet_id                 = var.subnet_id
  network_security_group_id = var.nsg_id
}

resource "azurerm_virtual_machine" "host" {
  connection {
    type = "ssh"
    user = var.admin_user
    bastion_host = var.bastion_public_ip
    bastion_port = var.bastion_ssh_port
    bastion_user = local.real_bastion_user
    # host does need to be set in Terraform >= v0.12, but cannot use self.private_ip because the resource doesn't know it
    host = azurerm_network_interface.stnic.private_ip_address
  }
  name = "vm-${local.hostbase}"
  location = var.resource_group_location
  resource_group_name = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.stnic.id]
  vm_size = var.host_size
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "OpenLogic"
    offer = "CentOS"
    sku = "7.7"
    version = "latest"
  }
  storage_os_disk {
    name = "osdisk1-vm-${local.hostbase}"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name = var.hostname
    admin_username = var.admin_user
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.admin_user}/.ssh/authorized_keys"
      key_data = file(var.public_key_path)
    }
  }
  identity {
    type = var.identity_type
  }

  #
  # Azure-specific
  #
  # after the install, we can now upload the agent configuration files
  provisioner "file" {
    content = data.template_file.omsagent-conf.rendered
    destination = "/tmp/omsagent.conf"
  }
  provisioner "file" {
    content = data.template_file.rsyslog-95-omsagent-conf.rendered
    destination = "/tmp/95-omsagent.conf"
  }
  # then restart logging services
  provisioner "remote-exec" {
    inline = [
      # manually get, but only install OMS agent if LAA workspace ID defined
      "wget https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh",
      var.log_analytics_workspace_id == "" ? "echo no_log_analytics_workspace" : local.setup_log_analytics_workspace,
      # move config files into target locations (requires sudo)
      var.log_analytics_workspace_id == "" ? "echo no_log_analytics_workspace" : local.setup_move_laa_files,
      # restart the [omsagent and rsyslog] services to pick up the latest config
      var.log_analytics_workspace_id == "" ? "echo no_log_analytics_workspace" : "sudo /opt/microsoft/omsagent/bin/service_control restart",
      "sudo /usr/bin/systemctl restart rsyslog",
    ]
  }
  #
  # STANDARD (puppetmastered, v1.8)
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
    })]
  }
  # when destroying this resource, clean the old certs off the puppet master
  provisioner "local-exec" {
    command = "sudo ${local.puppet_server_exec} ca clean --certname ${var.hostname}.${var.host_domain}; sudo ${local.puppet_exec} node deactivate ${var.hostname}.${var.host_domain}"
    on_failure = continue
    when = destroy
  }
  # /STANDARD (puppetmastered, v1.8)

  # timeouts block not supported by this resource
  #timeouts {
  #  # long timeout to allow for puppet run
  #  create = "30m"
  #}
  # tag for testing purposes and remotely identifying
  tags = {
    name = var.hostname
    project = var.project
    account = var.account
    environment = terraform.workspace
  }
}

# configuration files for OMSAgent
data "template_file" "omsagent-conf" {
  template = file("${path.module}/templates/omsagent.conf")
  vars = {
    workspace_id = var.log_analytics_workspace_id
  }
}
data "template_file" "rsyslog-95-omsagent-conf" {
  template = file("${path.module}/templates/rsyslog-95-omsagent.conf")
  vars = {
    workspace_id = var.log_analytics_workspace_id
    min_log_level = var.min_log_level
  }
}

# load DNS zone then create new A record
data "azurerm_dns_zone" "tzone" {
  name = var.host_domain
  resource_group_name = var.dns_resource_group_name
  count = (var.create_dns_entry == "yes" ? 1 : 0)
}
resource "azurerm_dns_a_record" "dnsrec" {
  name                = var.hostname
  zone_name           = data.azurerm_dns_zone.tzone.0.name
  resource_group_name = data.azurerm_dns_zone.tzone.0.resource_group_name
  ttl                 = "300"
  records             = [var.public_ip_address]
  count               = (var.create_dns_entry == "yes" ? 1 : 0)
}
