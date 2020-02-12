#
# create-azure-vm-puppetmless
# OS support: CentOS
#

# default provider configured in root (upstream) module

locals {
  # STANDARD (puppetmless, v1.8)
  puppet_target_repodir = "/etc/puppetlabs/puppetmless"
  puppet_source = "${path.module}/../../../puppet"
  puppet_run = "/opt/puppetlabs/bin/puppet apply -t --hiera_config=${local.puppet_target_repodir}/environments/${var.puppet_environment}/hiera.yaml --modulepath=${local.puppet_target_repodir}/modules:${local.puppet_target_repodir}/environments/shared/modules:${local.puppet_target_repodir}/environments/${var.puppet_environment}/modules ${local.puppet_target_repodir}/environments/${var.puppet_environment}/manifests/${var.puppet_manifest_name}"
  real_bastion_user = var.bastion_user == "" ? var.admin_user : var.bastion_user
  # /STANDARD (puppetmless, v1.8), custom variables
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
  network_security_group_id = var.nsg_id

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

resource "azurerm_virtual_machine" "host" {
  connection {
    type = "ssh"
    user = var.admin_user
    bastion_host = var.bastion_public_ip
    bastion_port = var.bastion_ssh_port
    bastion_user = local.real_bastion_user
    # host does need to be set in Terraform >= v0.12, but cannot use self.private_ip because the resource doesn't know it
    host = azurerm_network_interface.stnic.private_ip_address
    port = "22"
  }
  name = "vm-${local.hostbase}"
  location = var.resource_group_location
  resource_group_name = var.resource_group_name
  network_interface_ids = [
    azurerm_network_interface.stnic.id]
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
