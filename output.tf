# Outputs
output "virtual_network_id" {
  value = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  value = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}

output "network_security_group_ids" {
  value = var.create_security_groups ? { for name, nsg in azurerm_network_security_group.this : name => nsg.id } : {}
}

output "route_table_ids" {
  value = var.create_route_tables ? { for name, rt in azurerm_route_table.this : name => rt.id } : {}
}