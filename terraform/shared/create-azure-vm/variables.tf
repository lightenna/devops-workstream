
variable "project" {}
variable "account" {}
variable "hostname" {}
variable "ssh_additional_port" {
  default = ""
}
variable "admin_user" {}
variable "public_key_path" {}
variable "min_log_level" {
  default = "info"
}
variable "subnet_id" {}
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
variable "nsg_id" {}
variable "log_analytics_workspace_id" {
  # no explicit log analytics workspace, no LAA installed
  default = ""
}
variable "log_analytics_workspace_key" {
  # no explicit log analytics workspace, no LAA installed
  default = ""
}
variable "resource_group_location" {}
variable "resource_group_name" {}
variable "bastion_public_ip" {
  # no explicit bastion ip, don't use a bastion
  default = ""
}
variable "bastion_ssh_port" {
  default = "22"
}
variable "puppet_environment" {
  default = "lightenna"
}
variable "puppet_manifest_name" {
  # empty to evaluate the whole puppet directory
  default = ""
}
