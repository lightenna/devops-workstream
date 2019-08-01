#
# Variables can be overridden

variable "unique_append" {}

variable "region" {
  default = "uksouth"
}

# resource group must be passed in to avoid dependency errors
variable "resource_group_location" {}
variable "resource_group_name" {}
