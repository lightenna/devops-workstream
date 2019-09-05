#
# create-azure-vm-puppetmless
# OS support: CentOS
#

provider "azurerm" {}

locals {
  # STANDARD (puppetmless, v1.1)
  home_directory = "${ var.admin_user == "root" ? "/root" : "/home/${var.admin_user}"}"
  puppet_target_repodir = "/etc/puppetlabs/puppetmless"
  puppet_source = "${path.module}/../../../puppet"
  puppet_apply = "/opt/puppetlabs/bin/puppet apply -dvt --hiera_config=${local.puppet_target_repodir}/environments/${var.puppet_environment}/hiera.yaml --modulepath=${local.puppet_target_repodir}/modules:${local.puppet_target_repodir}/environments/shared/modules:${local.puppet_target_repodir}/environments/${var.puppet_environment}/modules ${local.puppet_target_repodir}/environments/${var.puppet_environment}/manifests/${var.puppet_manifest_name}"
  setup_ssh_additional_port = "sudo /usr/sbin/semanage port -m -t ssh_port_t -p tcp ${var.ssh_additional_port} ; sudo sed -i 's/\\#Port 22/Port 22\\nPort ${var.ssh_additional_port}/g' /etc/ssh/sshd_config ; sudo service sshd restart"
  # /STANDARD (puppetmless, v1.1), custom variables
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
  location = "${var.resource_group_location}"
  resource_group_name = "${var.resource_group_name}"
  network_security_group_id = "${var.nsg_id}"

  ip_configuration {
    name = "ipcfg-stnic-${local.hostbase}"
    subnet_id = "${var.subnet_id}"
    private_ip_address = "${var.private_ip}"
    private_ip_address_allocation = "${var.private_ip_address_allocation}"
    public_ip_address_id = "${var.public_ip_address_id}"
  }
  tags = {
    name = "stnic-${local.hostbase}"
    project = "${var.project}"
    account = "${var.account}"
    environment = "${terraform.workspace}"
  }
}

resource "azurerm_virtual_machine" "host" {
  connection {
    type = "ssh"
    user = "${var.admin_user}"
    bastion_host = "${var.bastion_public_ip}"
    bastion_port = "${var.bastion_ssh_port}"
    # bastion_user doesn't need to be set as defaults to same value as 'user'
    # host does need to be set in Terraform >= v0.12, but cannot use self.private_ip because the resource doesn't know it
    host = "${azurerm_network_interface.stnic.private_ip_address}"
  }
  name = "vm-${local.hostbase}"
  location = "${var.resource_group_location}"
  resource_group_name = "${var.resource_group_name}"
  network_interface_ids = [
    "${azurerm_network_interface.stnic.id}"]
  vm_size = "${var.host_size}"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "OpenLogic"
    offer = "CentOS"
    sku = "7.5"
    version = "latest"
  }
  storage_os_disk {
    name = "osdisk1-vm-${local.hostbase}"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name = "${var.hostname}"
    admin_username = "${var.admin_user}"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.admin_user}/.ssh/authorized_keys"
      key_data = "${file(var.public_key_path)}"
    }
  }
  #
  # STANDARD (puppetmless, v1.1)
  #
  # wait for cloud provider to finish install its stuff, otherwise yum/dpkg collide [standard]
  provisioner "remote-exec" {
    inline = ["sleep 60"]
  }
  # run any host-specific commands [standard]
  provisioner "remote-exec" {
    inline = "${split(";", var.host_specific_commands)}"
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
      "${var.ssh_additional_port == "22" ? "echo no_additional_port" : local.setup_ssh_additional_port}",
    ]
  }
  # upload puppet manifests [standard]
  provisioner "file" {
    source = "${local.puppet_source}"
    # transfer to intermediary folder
    destination = "/tmp/puppet-additions"
    # can't go straight to final destination because user doesn't have access
    # and "file" provisioners have no sudo escalation
  }
  # prepare and execute puppet [standard]
  provisioner "remote-exec" {
    inline = [
      # set the admin user's password
      "sudo bash -c \"echo -e '${random_string.admin_password.result}\n${random_string.admin_password.result}' | passwd ${var.admin_user}\"",
      # add admin user to wheel group to allow passworded sudo (redundant for root)
      "sudo usermod -aG wheel ${var.admin_user}",
      # merge into target puppet folder
      "sudo mkdir -p ${local.puppet_target_repodir}/",
      "sudo mv /tmp/puppet-additions/* ${local.puppet_target_repodir}/",
      # give admin user perms to allow post-terraform rsync
      "sudo chown -R ${var.admin_user}:${var.admin_user} ${local.puppet_target_repodir}/",
      # run puppet masterless but using uploaded modules; this is time-consuming so don't wait to complete
      "sudo bash -c 'nohup ${local.puppet_apply} > ${local.home_directory}/puppet_apply.out & 2>&1'", #
      # wait a few seconds, then show a snippet from the run
      "sleep 6",
      "tail -n100 ${local.home_directory}/puppet_apply.out",
    ]
  }
  # /STANDARD (puppetmless, v1.1)
  #
  # Azure-specific
  #
  # after the install, we can now upload the agent configuration files
  provisioner "file" {
    content = "${data.template_file.omsagent-conf.rendered}"
    destination = "/tmp/omsagent.conf"
  }
  provisioner "file" {
    content = "${data.template_file.rsyslog-95-omsagent-conf.rendered}"
    destination = "/tmp/95-omsagent.conf"
  }
  # then restart logging services
  provisioner "remote-exec" {
    inline = [
      # manually get, but only install OMS agent if LAA workspace ID defined
      "wget https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh",
      "${var.log_analytics_workspace_id == "" ? "echo no_log_analytics_workspace" : local.setup_log_analytics_workspace}",
      # move config files into target locations (requires sudo)
      "${var.log_analytics_workspace_id == "" ? "echo no_log_analytics_workspace" : local.setup_move_laa_files}",
      # restart the [omsagent and rsyslog] services to pick up the latest config
      "${var.log_analytics_workspace_id == "" ? "echo no_log_analytics_workspace" : "sudo /opt/microsoft/omsagent/bin/service_control restart"}",
      "sudo /usr/bin/systemctl restart rsyslog",
    ]
  }
  # finally clean up
  provisioner "remote-exec" {
    inline = [
      # finally, fix for Windows Azure Linux Agent's gaping security hole so that from now on
      "sudo rm /etc/sudoers.d/waagent",
    ]
  }

  # timeouts block not supported by this resource
  #timeouts {
  #  # long timeout to allow for puppet run
  #  create = "30m"
  #}
  # tag for testing purposes and remotely identifying
  tags = {
    name = "${var.hostname}"
    project = "${var.project}"
    account = "${var.account}"
    environment = "${terraform.workspace}"
  }
}

# configuration files for OMSAgent
data "template_file" "omsagent-conf" {
  template = "${file("${path.module}/templates/omsagent.conf")}"
  vars = {
    workspace_id = "${var.log_analytics_workspace_id}"
  }
}
data "template_file" "rsyslog-95-omsagent-conf" {
  template = "${file("${path.module}/templates/rsyslog-95-omsagent.conf")}"
  vars = {
    workspace_id = "${var.log_analytics_workspace_id}"
    min_log_level = "${var.min_log_level}"
  }
}
