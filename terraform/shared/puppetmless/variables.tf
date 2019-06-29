
variable "aws_region" {}
variable "aws_ami" {}
variable "aws_security_group_id" {}
variable "aws_subnet_id" {}
variable "bastion_host" {}
variable "host_name" {}

variable "local_domain" {
  description = "Name of the domain used locally in this environment"
  default = "localdomain"
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  default = "devops_simple_key"
}

variable "manifest_name" {
  description = "Name of the puppet manifest to apply to this host"
  default = "host-puppetmless.pp"
}

