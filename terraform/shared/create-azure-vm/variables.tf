
# sensible defaults
variable "project" {
  default = "wrks"
}

variable "account" {
  default = "dvo"
}

variable "hostname" {
  default = "generic"
}

variable "pkgman" {
  default = "yum"
}

variable "host_specific_commands" {
  type = "string"
  description = "semi-colon (;) separated list of strings"
  default = "sudo yum -y install epel-release;sudo rpm -Uvh https://yum.puppetlabs.com/puppet6/puppet6-release-el-7.noarch.rpm"
}

variable "host_domain" {
  default = "localdomain"
}

variable "host_os_image" {
  default = "centos-7-x64"
}

variable "host_size" {
  default = "Standard_B1ms" # Standard_B1ms £0.0206/hour, £14.83/month
}

variable "admin_user" {
  # terraform runs as rootlike, sudos to run puppet as root
  default = "rootlike"
}

variable "public_key_path" {}
variable "subnet_id" {}
variable "nsg_id" {}
variable "resource_group_location" {}
variable "resource_group_name" {}

variable "min_log_level" {
  default = "info"
}

variable "private_ip" {
  # no explicit private_ip, so auto-generate a dynamic private IP
  default = ""
}

variable "private_ip_address_allocation" {
  default = "Dynamic"
}

variable "public_ip_address" {
  # no explicit public_ip, none allocated
  default = ""
}

variable "public_ip_address_id" {
  # no explicit public_ip, none allocated
  default = ""
}

variable "log_analytics_workspace_id" {
  # no explicit log analytics workspace, no LAA installed
  default = ""
}

variable "log_analytics_workspace_key" {
  # no explicit log analytics workspace, no LAA installed
  default = ""
}

variable "bastion_public_ip" {
  # no explicit bastion ip, don't use a bastion
  default = ""
}
variable "bastion_ssh_port" {
  default = "22"
}

variable "ssh_additional_port" {
  # port 22 to indicate no additional port
  default = "22"
}

variable "puppet_environment" {
  default = "workstream"
}

variable "puppet_manifest_name" {
  # empty to evaluate the whole puppet directory
  default = ""
}
