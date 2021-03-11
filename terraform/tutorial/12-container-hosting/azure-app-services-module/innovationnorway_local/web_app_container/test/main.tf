variable "location" {
  type    = string
  default = "westeurope"
}

resource "random_id" "test" {
  byte_length = 2
}

resource "azurerm_resource_group" "test" {
  name     = format("test-%s", random_id.test.hex)
  location = var.location
}

module "web_app_container" {
  source = "../"

  name = format("test-%s", random_id.test.hex)

  resource_group_name = azurerm_resource_group.test.name

  container_image = "innovationnorway/go-hello-world"

  plan = {
    sku_size = "B1"
  }
}

data "azurerm_app_service" "test" {
  name                = module.web_app_container.name
  resource_group_name = azurerm_resource_group.test.name
}

data "http" "test" {
  url = format("https://%s", module.web_app_container.hostname)
}

module "test_assertions" {
  source = "innovationnorway/assertions/test"
  equals = [
    {
      name = "has expected content"
      got  = chomp(data.http.test.body)
      want = "Hello, world!"
    },
    {
      name = "is loaded at all times"
      got  = data.azurerm_app_service.test.site_config.0.always_on
      want = true
    }
  ]
}
