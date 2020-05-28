#
# Comment

# store state locally for shared IAC to avoid bootstrapping
terraform {
  backend "local" {
  }
}

provider "azurerm" {
  features {}
}

# setup local variables, e.g. local.my_var
locals {
  name = "world"
}

output "message" {
  value = "Hello ${local.name}, unique_id (${var.unique_id}) in `${terraform.workspace}` environment"
}

