#
# create-azure-vm-puppetmastered
# OS support: CentOS
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
# render a local template file for puppet.conf
data "template_file" "puppet_conf" {
  template = file("${path.module}/templates/puppet.conf.tpl")
  vars = {
    puppet_environment = var.puppet_environment
    puppet_master_fqdn = var.puppet_master_fqdn
    puppet_certname = "${var.hostname}.${var.host_domain}"
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
