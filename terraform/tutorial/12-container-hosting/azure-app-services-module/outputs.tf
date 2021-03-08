output "app_service_hostname" {
  value = module.web_app_container.hostname
}

output "app_URL" {
  value = "https://${module.web_app_container.hostname}"
}
