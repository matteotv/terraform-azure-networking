# Module to create Azure networking resources
# This module provisions a virtual network, subnets, optional network security groups
# and optional route tables. Input variables control whether security groups and
# route tables are created. Outputs return the IDs of the created resources.

locals {
  # Convert the list of subnet objects into a map keyed by subnet name
  Subnet_Details = {
    for subnet in var.subnets : subnet.name => {
      name              = subnet.name
      range             = subnet.range
      private           = lookup(subnet, "private", false)
      security_group    = lookup(subnet, "security_group", null)
      route_table       = lookup(subnet, "route_table", null)
      service_endpoints = lookup(subnet, "service_endpoints", [])
      delegation        = lookup(subnet, "delegation", null)
    }
  }
}

# Create the virtual network
resource "azurerm_virtual_network" "this" {
  name                = "${var.app_name}-${var.azure_env}-vnet"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space

  tags = merge(var.tags, {
    name = "${var.app_name}-${var.azure_env}-vnet"
  })
}

# Create subnets dynamically from the provided list
resource "azurerm_subnet" "this" {
  for_each = local.Subnet_Details

  name                            = "${each.value.name}-${var.azure_env}-snet"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = each.value.range
  default_outbound_access_enabled = each.value.private ? false : true
  service_endpoints               = each.value.service_endpoints

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# Optionally create network security groups
resource "azurerm_network_security_group" "this" {
  for_each = var.create_security_groups && length(var.security_groups) > 0 ? { for sg in var.security_groups : sg.name => sg } : {}

  name                = "${var.app_name}-${var.azure_env}-${each.value.name}-nsg"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = { for r in each.value.security_rules : r.name => r }
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
  tags = merge(var.tags, {
    name = "${var.app_name}-${var.azure_env}-${each.value.name}-nsg"
  })
}

# Associate subnets with security groups where specified
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.create_security_groups && length(var.security_groups) > 0 ? {
    for name, subnet in local.Subnet_Details : name => subnet.security_group if subnet.security_group != null
  } : {}

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.value].id
}

# Optionally create route tables
resource "azurerm_route_table" "this" {
  for_each = var.create_route_tables && length(var.routes) > 0 ? { for route in var.routes : route.name => route } : {}

  name                = "${var.app_name}-${var.azure_env}-${each.key}-rt"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  dynamic "route" {
    for_each = { for r in each.value.details : r.name => r }
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)
    }
  }
  tags = merge(var.tags, {
    name = "${var.app_name}-${var.azure_env}-${each.key}-rt"
  })
}

# Associate subnets with route tables where specified
resource "azurerm_subnet_route_table_association" "this" {
  for_each = var.create_route_tables && length(var.routes) > 0 ? {
    for name, subnet in local.Subnet_Details : name => subnet.route_table if subnet.route_table != null
  } : {}

  subnet_id      = azurerm_subnet.this[each.key].id
  route_table_id = azurerm_route_table.this[each.value].id
}

