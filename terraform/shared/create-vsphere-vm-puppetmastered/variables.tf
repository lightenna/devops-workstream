
#
# Mandatory, general variables
#
variable "host_os_image" {}
variable "private_ip_address" {}
variable "puppet_master_fqdn" {}

#
# Mandatory, vSphere variables
#
variable "vsphere_datacenter" {}
variable "vsphere_cluster" {}
variable "vsphere_datastore" {}
variable "vsphere_network" {}
variable "vsphere_gateway" {}
variable "vsphere_dns" {}

#
# Optional variables, vSphere
#

variable "vsphere_customize_timeout" {
  default = "40" # minutes
}

variable "vsphere_netmask" {
  default = "24"
}

variable "vsphere_linked_clone" {
  description = "Use linked clone to create the vSphere virtual machine from the template (true/false). If you would like to use the linked clone feature, your template need to have one and only one snapshot"
  default = "false"
}

variable "vsphere_cpu" {
  description = "Number of vCPU for the vSphere virtual machines"
  default = "2"
}

variable "vsphere_ram" {
  description = "Amount of RAM for the vSphere virtual machines (example: 2048)"
  default = "4096"
}

variable "vsphere_cpu_hot_add_enabled" {
  description = "CPU hot-add enabled on the virtual machine"
  default = "true"
}

variable "vsphere_memory_hot_add_enabled" {
  description = "Memory hot-add enabled on the virtual machine"
  default = "true"
}

variable "vsphere_num_cores_per_socket" {
  description = "The number of cores per socket allocated to the virtual machine"
  # if empty string, reuse vsphere_cpu as num_cores_per_socket
  default = ""
}

#
# Optional, general variables
#

variable "hostname" {
  default = "generic"
}

variable "host_domain" {
  default = "localdomain"
}

variable "admin_user" {
  # terraform runs puppet as OS default on AWS, escalated with sudo
  default = "centos"
}

variable "pkgman" {
  default = "yum"
}

variable "host_specific_commands" {
  type = string
  description = "semi-colon (;) separated list of strings"
  default = "sudo yum -y install epel-release;sudo rpm -Uvh https://yum.puppetlabs.com/puppet6/puppet6-release-el-7.noarch.rpm"
}

variable "bastion_public_ip" {
  # no explicit bastion ip, don't use a bastion
  default = ""
}

variable "bastion_user" {
  default = ""
}

variable "bastion_ssh_port" {
  default = "22"
}

variable "bastion_use_external" {
  default = "false"
}

variable "ssh_additional_port" {
  # port 22 to indicate no additional port
  default = "22"
}

variable "puppet_mode" {
  default = "fire-and-forget"
}

variable "puppet_sleeptime" {
  default = 120
}

variable "puppet_environment" {
  default = "prod"
}

variable "puppet_manifest_name" {
  # empty to evaluate the whole puppet directory
  default = ""
}

variable "create_dns_entry" {
  default = "no"
}

variable "facts" {
  default = {}
}
