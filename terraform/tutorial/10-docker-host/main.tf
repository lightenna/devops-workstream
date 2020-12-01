#
# Create a Docker host using a module and an array command line
# Cloud: Azure

locals {
  # use a unique ID for all resources based on a random string unless one is specified
  unique_append = var.unique_id == "" ? "-${random_string.unique_key.result}" : "-${var.unique_id}"
  admin_user = "rootlike"
}

resource "random_string" "unique_key" {
  length = 8
  upper = false
  special = false
}

# resource group name uses derived (local) unique_append, but region comes from external, default in variables.tf
resource "azurerm_resource_group" "rg" {
  name = "rg${local.unique_append}"
  location = var.region
}

# create network resources
module "net" {
  source = "./azure-network"
  unique_append = local.unique_append
  region = var.region

  # pass in shared resource group
  resource_group_location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# create some VMs
module "vm1" {
  source = "./azure-virtual-machine"
  unique_append = local.unique_append
  hostname = "host1"
  public_key_path = "~/.ssh/id_rsa_devops_simple_key.pub"
  region = var.region
  admin_user = local.admin_user
  command_list = [
    "sleep 60",
    # docker install
    "sudo bash -c 'curl -fsSL https://get.docker.com/ | sh'",
    # docker-compose install
    "sudo curl -L \"https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
    "sudo chmod +x /usr/local/bin/docker-compose",
    # add admin user to docker group to allow it to run docker commands
    "sudo usermod -aG docker ${local.admin_user}",
    # start docker service and enable it!
    "sudo systemctl --now enable docker",
  ]

  # pass in shared resource group
  resource_group_location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # pass in network IDs based on module output to ensure dependency
  nsg_id = module.net.nsg_id
  subnet_id = module.net.subnet_id
}

output "host1_ssh" {
  value = "ssh -A -p 22 ${module.vm1.admin_user}@${module.vm1.ip}"
}

# docker run --name something -v /home/rootlike/html:/usr/share/nginx/html:ro -p 80:80 -d nginx
# docker run --name something --user=1000:1000 -v /home/rootlike/html:/usr/share/nginx/html:ro -p 8081:8080 -d nginxpriv
