#
# Create virtual network using a module
# Cloud: Azure

# store state locally for shared IAC to avoid bootstrapping
terraform {
  backend "local" {
  }
}

module "left" {
  source    = "./brick"
  width     = 40
}

output "left_volume" {
  value = module.left.vol
}

module "right" {
  source    = "./brick"
  width     = 30
}

output "right_volume" {
  value = "${module.right.vol} cm³"
}

output "total_measured_width" {
  value = module.left.measured_width + module.right.measured_width
}
