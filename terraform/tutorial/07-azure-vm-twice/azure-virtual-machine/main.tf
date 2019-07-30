#
# Create virtual machine
# Cloud: Azure

locals {
  hostbase = "${var.hostname}-${terraform.workspace}${var.unique_append}"
}

# refer to external resources by name
data "azurerm_resource_group" "rg" {
  name = "rg${var.unique_append}"
}

data "azurerm_virtual_network" "default" {
  name                 = "default-network${var.unique_append}"
  resource_group_name  = "${data.azurerm_resource_group.rg.name}"
}

data "azurerm_subnet" "intnet" {
  name                 = "internal-subnet${var.unique_append}"
  resource_group_name  = "${data.azurerm_resource_group.rg.name}"
  virtual_network_name = "${data.azurerm_virtual_network.default.name}"
}

data "azurerm_network_security_group" "nsg_public" {
  name = "nsgpub${var.unique_append}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
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

# create a network interface card (NIC) for our first host
resource "azurerm_network_interface" "stnic" {
  name = "stnic-${local.hostbase}"
  location = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  network_security_group_id = "${data.azurerm_network_security_group.nsg_public.id}"

  ip_configuration {
    name = "ipcfg-stnic-${local.hostbase}"
    subnet_id = "${data.azurerm_subnet.intnet.id}"
    private_ip_address = ""
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = ""
  }
  tags = {
    name = "stnic-${local.hostbase}"
    environment = "${terraform.workspace}"
  }
}

# create public IP address
resource "azurerm_public_ip" "pubipbst" {
  name                         = "pubip-${local.hostbase}"
  location                     = "${data.azurerm_resource_group.rg.location}"
  resource_group_name          = "${data.azurerm_resource_group.rg.name}"
  allocation_method = "Static"
  # public_ip_address_allocation now known as allocation_method
  tags = {
    name = "pubip-${local.hostbase}"
    environment = "${terraform.workspace}"
  }
}

resource "azurerm_virtual_machine" "host" {
  connection {
    type = "ssh"
    user = "${var.admin_user}"
    # host does need to be set in Terraform >= v0.12, but cannot use self.private_ip because the resource doesn't know it
    host = "${azurerm_network_interface.stnic.private_ip_address}"
  }
  name = "vm-${local.hostbase}"
  location = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
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
  # wait for cloud provider to finish install its stuff, otherwise yum/dpkg collide [standard]
  provisioner "remote-exec" {
    inline = ["sleep 60"]
  }
  # tag for testing purposes and remotely identifying
  tags = {
    name = "${var.hostname}"
    environment = "${terraform.workspace}"
  }
}