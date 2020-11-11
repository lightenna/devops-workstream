#
# Create virtual machine
# Cloud: Azure

locals {
  hostbase = "${var.hostname}-${terraform.workspace}${var.unique_append}"
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

# create public IP address
resource "azurerm_public_ip" "pubipbst" {
  name                         = "pubip-${local.hostbase}"
  location                     = var.resource_group_location
  resource_group_name          = var.resource_group_name
  allocation_method = "Static"
  # public_ip_address_allocation now known as allocation_method
  tags = {
    name = "pubip-${local.hostbase}"
    environment = terraform.workspace
  }
}

# create a network interface card (NIC) for our first host
resource "azurerm_network_interface" "stnic" {
  name = "stnic-${local.hostbase}"
  location = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name = "ipcfg-stnic-${local.hostbase}"
    subnet_id = var.subnet_id
    private_ip_address = ""
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pubipbst.id
  }
  tags = {
    name = "stnic-${local.hostbase}"
    environment = terraform.workspace
  }
}

resource "azurerm_linux_virtual_machine" "host" {
  connection {
    type = "ssh"
    user = var.admin_user
    host = azurerm_public_ip.pubipbst.ip_address
  }
  name = "vm-${local.hostbase}"
  location = var.resource_group_location
  resource_group_name = var.resource_group_name
  network_interface_ids = [
    azurerm_network_interface.stnic.id]

  source_image_reference  {
    publisher = "OpenLogic"
    offer = "CentOS"
    sku = "7.5"
    version = "latest"
  }
  admin_username = var.admin_user
  admin_password = var.admin_password
  size = var.host_size
  os_disk {
    name = "osdisk1-vm-${local.hostbase}"
    caching = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  admin_ssh_key {
    username   = var.admin_user
    public_key = file(var.public_key_path)
  }
  disable_password_authentication = false
  # wait for cloud provider to finish install its stuff, otherwise yum/dpkg collide [standard]
  provisioner "remote-exec" {
    inline = ["sleep 60"]
  }
  # tag for testing purposes and remotely identifying
  tags = {
    name = var.hostname
    environment = terraform.workspace
  }
}