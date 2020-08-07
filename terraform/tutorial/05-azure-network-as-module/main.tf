#
# Create virtual network using a module
# Cloud: Azure

module "net" {
  source    = "./azure-network"
  unique_id = var.unique_id
  region    = var.region
}

