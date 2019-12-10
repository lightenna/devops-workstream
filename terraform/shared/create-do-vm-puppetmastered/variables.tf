variable "do_token" {
  # set variable using -var="do_token=..." or TF_VAR_do_token environment variable (preferred)
}

variable "project" {
  default = "projname"
}

variable "account" {
  default = "orgname"
}

variable "hostname" {
  default = "generic"
}

variable "host_domain" {
  default = "localdomain"
}

variable "host_os_image" {
  default = "centos-7-x64"
}

variable "admin_user" {
  # terraform runs puppet as root
  default = "root"
}

variable "pkgman" {
  default = "yum"
}

variable "host_size" {
  default = "s-1vcpu-1gb"
}

variable "host_tags" {
  type = string
  description = "semi-colon (;) separated list of strings"
  default = ""
}

variable "host_specific_commands" {
  type = string
  description = "semi-colon (;) separated list of strings"
  default = "sudo yum -y install epel-release;sudo rpm -Uvh https://yum.puppetlabs.com/puppet6/puppet6-release-el-7.noarch.rpm"
}

variable "region" {
  default = "lon1"
}

variable "ssh_key_name" {}

variable "bastion_public_ip" {
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
