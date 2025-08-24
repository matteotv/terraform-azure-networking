# Outputs
output "virtual_network" {
  value = azurerm_virtual_network.this
}

output "subnets" {
  value = { for name, subnet in azurerm_subnet.this : name => subnet }
}

output "network_security_groups" {
  value = var.create_security_groups ? { for name, nsg in azurerm_network_security_group.this : name => nsg } : {}
}

output "route_tables" {
  value = var.create_route_tables ? { for name, rt in azurerm_route_table.this : name => rt } : {}
}