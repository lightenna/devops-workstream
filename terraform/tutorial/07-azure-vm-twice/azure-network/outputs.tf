#
# Output variables for other modules to use
#

output "nsg_id" {
  value = "${azurerm_network_security_group.nsg_public.id}"
}
output "subnet_id" {
  value = "${azurerm_subnet.intnet.id}"
}
