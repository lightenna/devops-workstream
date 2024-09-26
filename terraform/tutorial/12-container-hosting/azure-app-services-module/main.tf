#
# Create a container hosting environment
# Cloud: Azure

locals {
  # use a unique ID for all resources based on a random string unless one is specified
  unique_append = var.unique_id == "" ? random_string.unique_key.result : var.unique_id
  hostbase = "${var.project}-${local.unique_append}"
  IMAGE_NAME = "dockcloudhost"
  ACR_NAME = "acr8conhost8dvw"
  ACR_TARGET = "acr8conhost8dvw.azurecr.io"
}

resource "random_string" "unique_key" {
  length = 8
  upper = false
  special = false
}

# resource group name uses derived (local) unique_append, but region comes from external, default in variables.tf
resource "azurerm_resource_group" "rg" {
  name = "rg-${local.hostbase}"
  location = var.region
}

# use community module to spin-up Azure App Service instance
module "web_app_container" {
  source = "./innovationnorway_local/web_app_container"
  name = var.project
  resource_group_name = azurerm_resource_group.rg.name
  container_type = "docker"
  # temporarily use public container image for testing
  container_image = "nginx:latest"
  # identify private container image with credentials to pull it
  #docker_registry_url = "https://${local.ACR_TARGET}"
  #docker_registry_username = data.azurerm_key_vault_secret.adminuser.value
  #docker_registry_password = data.azurerm_key_vault_secret.adminpass.value
  #container_image = "${local.ACR_TARGET}/${local.IMAGE_NAME}:latest"
  #port = "3031"
  # needs explicit depends_on as module's data resource needs rg to exist first
  depends_on = [
    azurerm_resource_group.rg]
}
