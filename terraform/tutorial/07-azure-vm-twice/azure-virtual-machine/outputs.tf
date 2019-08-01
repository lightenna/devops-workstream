
output "admin_user" {
  value = "${var.admin_user}"
}
output "ip" {
  value = "${azurerm_public_ip.pubipbst.ip_address}"
}
