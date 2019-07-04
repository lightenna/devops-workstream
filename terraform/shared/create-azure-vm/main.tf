provider "azurerm" {}

locals {
  hostbase = "${var.hostname}-${terraform.workspace}-${var.project}-${var.account}"
  home_directory = "${ var.admin_user == "root" ? "/root" : "/home/${var.admin_user}"}"
  puppet_target_repodir = "/etc/puppetlabs/puppetmless"
  puppet_source_relative = "${path.module}/../../../puppet"
  puppet_apply = "/opt/puppetlabs/bin/puppet apply -dvt --hiera_config=${local.puppet_target_repodir}/environments/${var.puppet_environment}/hieradata/puppetmless-only/hiera.yaml --modulepath=${local.puppet_target_repodir}/modules ${local.puppet_target_repodir}/environments/${var.puppet_environment}/manifests/${var.puppet_manifest_name}"
  setup_ssh_additional_port = "sudo /usr/sbin/semanage port -m -t ssh_port_t -p tcp ${var.ssh_additional_port} ; sudo sed -i 's/\\#Port 22/Port 22\\nPort ${var.ssh_additional_port}/g' /etc/ssh/sshd_config ; sudo service sshd restart"
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
    # bastion_user = "${var.admin_user}"
    # host does need to be set in Terraform >= v0.12, but cannot use self.private_ip because the resource doesn't know it
    host = "${azurerm_network_interface.stnic.private_ip_address}"
  }
  name = "vm-${local.hostbase}"
  location = "${var.resource_group_location}"
  resource_group_name = "${var.resource_group_name}"
  network_interface_ids = [
    "${azurerm_network_interface.stnic.id}"]
  vm_size = "Standard_B1ms"
  # £12.84/month
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
      path = "${local.home_directory}/.ssh/authorized_keys"
      key_data = "${file(var.public_key_path)}"
    }
  }

  # update as AMI may be out-of-date
  provisioner "remote-exec" {
    inline = [
      # set the user's password
      "sudo bash -c \"echo '${random_string.admin_password.result}' | passwd '${var.admin_user}' --stdin\"",
      # add admin user to wheel group to allow passworded sudo
      "sudo usermod -aG wheel ${var.admin_user}",
      # no need to give temporary passwordless-sudo perms because /etc/sudoers.d/waagent already does it
      #"sudo bash -c \"echo '${var.admin_user} ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers\"",
      "sudo yum -y install deltarpm",
      # install EPEL
      "sudo yum -y install epel-release",
      # bring base install up-to-date
      #"sudo yum -y update",
      "sudo hostnamectl set-hostname ${var.hostname}",
      # install basic utilities
      "sudo yum -y install wget curl unzip htop",
      # install semanage for SELinux
      "sudo yum -y install policycoreutils-python",
      # make SSH available on additional port, only if set
      "${var.ssh_additional_port == "" ? "echo no_additional_port" : local.setup_ssh_additional_port}",
      # manually get, but only install OMS agent if LAA workspace ID defined
      "wget https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh",
      "${var.log_analytics_workspace_id == "" ? "echo no_log_analytics_workspace" : local.setup_log_analytics_workspace}",
    ]
  }

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
      # move config files into target locations (requires sudo)
      "${var.log_analytics_workspace_id == "" ? "echo no_log_analytics_workspace" : local.setup_move_laa_files}",
      # restart the [omsagent and rsyslog] services to pick up the latest config
      "${var.log_analytics_workspace_id == "" ? "echo no_log_analytics_workspace" : "sudo /opt/microsoft/omsagent/bin/service_control restart"}",
      "sudo /usr/bin/systemctl restart rsyslog",
    ]
  }
  # install puppet
  provisioner "remote-exec" {
    inline = [
      # install an up-to-date puppet agent
      "sudo rpm -ivh http://yum.puppet.com/puppet-release-el-7.noarch.rpm",
      "sudo yum -y install puppet-agent",
    ]
  }
  # upload puppet manifests
  provisioner "file" {
    source = "${local.puppet_source_relative}"
    # transfer to intermediary folder
    destination = "/tmp/puppet-additions"
    # can't go straight to final destination because user doesn't have access
    # and "file" provisioners have no sudo escalation
  }
  provisioner "remote-exec" {
    inline = [
      # merge into target puppet folder
      "sudo mkdir -p ${local.puppet_target_repodir}/",
      "sudo mv /tmp/puppet-additions/* ${local.puppet_target_repodir}/",
      # give admin user perms to allow post-terraform rsync
      "sudo chown -R ${var.admin_user}:${var.admin_user} ${local.puppet_target_repodir}/",
    ]
  }
  # kick off (masterless) puppet run on host
  provisioner "remote-exec" {
    inline = [
      # run puppet masterless but using uploaded modules; this is time-consuming
      "sudo ${local.puppet_apply} > ${local.home_directory}/puppet_apply.out 2>&1",
      # pull puppet run output back over terraform console channel (after run completes)
      "sudo cat ${local.home_directory}/puppet_apply.out"
    ]
  }
  # finally clean up
  provisioner "remote-exec" {
    inline = [
      # finally, fix for Windows Azure Linux Agent's gaping security hole so that from now on
      # sudo for ${var.admin_user} should require a password ${random_string.admin_password.result}
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
