#
# Create a container hosting environment
# Cloud: Azure

locals {
  # use a unique ID for all resources based on a random string unless one is specified
  unique_append = var.unique_id == "" ? random_string.unique_key.result : var.unique_id
  hostbase = "${var.project}-${local.unique_append}"
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

resource "azurerm_app_service_plan" "plan" {
  name = "aas-plan-${local.hostbase}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "service" {
  name = "aas-${local.hostbase}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.plan.id
  app_settings = {
    "PORT": "80"
  }
}

resource "azurerm_app_service_slot" "slot1" {
  name = "ass-slot1-${local.hostbase}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.plan.id
  app_service_name = azurerm_app_service.service.name
}

# nominate slot1 as the active slot
resource "azurerm_app_service_active_slot" "slotDemoActiveSlot" {
  resource_group_name = azurerm_resource_group.rg.name
  app_service_name = azurerm_app_service.service.name
  app_service_slot_name = azurerm_app_service_slot.slot1.name
}

