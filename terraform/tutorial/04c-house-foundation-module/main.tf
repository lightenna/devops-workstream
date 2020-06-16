#
# Create virtual network using a module
# Cloud: Azure

# store state locally for shared IAC to avoid bootstrapping
terraform {
  backend "local" {
  }
}

module "front_wall" {
  source    = "./brick"
  width     = var.across
}

module "side_wall" {
  source    = "./brick"
  width     = var.down
}

output "area" {
  value = "${module.front_wall.measured_width * module.side_wall.measured_width} cm²"
}
