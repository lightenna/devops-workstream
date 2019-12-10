
variable "project" {
  default = "projname"
}

variable "account" {
  default = "orgname"
}

variable "hostname" {
  default = "generic"
}

variable "pkgman" {
  default = "yum"
}

variable "host_specific_commands" {
  type = string
  description = "semi-colon (;) separated list of strings"
  default = "sudo yum -y install epel-release;sudo rpm -Uvh https://yum.puppet.com/puppet6-release-el-7.noarch.rpm"
}

variable "host_domain" {
  default = "localdomain"
}

variable "host_os_image" {
  default = "centos-7-x64"
}

variable "host_size" {
  # default = "Standard_B1ls" # 1vCPU,0.5GB £0.0044/hour, £3.17/month
  default = "Standard_B1s" # 1vCPU,1GB £0.0088/hour, £6.34/month
  # default = "Standard_B1ms" # 1vCPU,2GB £0.0176/hour, £12.67/month
}

variable "host_tags" {
  type = string
  description = "semi-colon (;) separated list of strings"
  default = ""
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
variable "identity_type" {
  # create system-managed identity even if not used
  default = "SystemAssigned"
}

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
variable "bastion_user" {
  default = ""
}
variable "bastion_ssh_port" {
  default = "22"
}

variable "ssh_additional_port" {
  # port 22 to indicate no additional port
  default = "22"
}

variable "puppet_mode" {
  default = "fire-and-forget"
}

variable "puppet_sleeptime" {
  default = 6
}

variable "puppet_environment" {
  default = "prod"
}

variable "puppet_master_fqdn" {}

variable "create_dns_entry" {
  default = "no"
}

variable "dns_resource_group_name" {
  # dns_resource_group_name required if create_dns_entry is yes
  default = ""
}
