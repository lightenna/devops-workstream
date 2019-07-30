#
# Variables can be overridden

variable "unique_append" {}
variable "public_key_path" {}

variable "region" {
  default = "uksouth"
}

variable "hostname" {
  default = "hostname"
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

