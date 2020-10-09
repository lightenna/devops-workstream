
terraform {
  required_version = ">= 0.13"
  required_providers {
    null = {
      source = "hashicorp/null"
    }
    oci = {
      source = "hashicorp/oci"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}
