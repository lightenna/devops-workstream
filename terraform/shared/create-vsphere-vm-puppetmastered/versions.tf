
terraform {
  required_version = ">= 0.13"
  required_providers {
    random = {
      source = "hashicorp/random"
    }
    vsphere = {
      source = "hashicorp/vsphere"
    }
  }
}
