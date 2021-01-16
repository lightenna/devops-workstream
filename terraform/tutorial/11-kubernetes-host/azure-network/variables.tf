#
# Variables can be overridden

variable "unique_append" {}

variable "region" {
  default = "uksouth"
}

variable "source_address_prefixes" {
  type = list
  default = ["*"]
}

# resource group must be passed in to avoid dependency errors
variable "resource_group_location" {}
variable "resource_group_name" {}
