
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
  # eu-west-2 centos 7 default
  default = "ami-c22236a6"
}

variable "admin_user" {
  # terraform runs puppet as OS default on AWS, escalated with sudo
  default = "centos"
}

variable "pkgman" {
  default = "yum"
}

variable "host_size" {
  default = "t2.micro"
}

variable "volume_size" {
  default = "8"
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
  default = "eu-west-2"
}

variable "ssh_key_name" {}

variable "subnet_id" {}
variable "nsg_id" {}

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

variable "iam_instance_profile" {
  default = ""
}

variable "create_dns_entry" {
  default = "no"
}

variable "facts" {
  default = {}
}
