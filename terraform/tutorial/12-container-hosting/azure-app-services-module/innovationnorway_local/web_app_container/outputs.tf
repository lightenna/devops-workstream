output "id" {
  value       = azurerm_app_service.main.id
  description = "The ID of the App Service."
}

output "name" {
  value       = azurerm_app_service.main.name
  description = "The name of the App Service."
}

output "hostname" {
  value       = azurerm_app_service.main.default_site_hostname
  description = "The default hostname for the App Service."
}

output "outbound_ips" {
  value       = split(",", azurerm_app_service.main.outbound_ip_addresses)
  description = "A list of outbound IP addresses for the App Service."
}

output "possible_outbound_ips" {
  value       = split(",", azurerm_app_service.main.possible_outbound_ip_addresses)
  description = "A list of possible outbound IP addresses for the App Service. Superset of outbound_ips."
}

output "plan" {
  value = {
    id = azurerm_app_service.main.app_service_plan_id
  }
  description = "A mapping of App Service plan properties."
}

output "identity" {
  value = {
    principal_id = azurerm_app_service.main.identity[0].principal_id
    ids          = azurerm_app_service.main.identity[0].identity_ids
  }
  description = "A mapping og identity properties for the web app."
}
