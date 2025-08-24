# Example usage of the networking module

# Assumes an existing resource group
resource "azurerm_resource_group" "rg" {
  name     = "example-rg"
  location = "uksouth"
}

module "networking" {
  source = "../"

  # Naming & scope
  app_name                = "networking"                 # prefix for resource names
  azure_env               = "prod"                       # env tag for naming
  resource_group_name     = azurerm_resource_group.rg.name
  resource_group_location = azurerm_resource_group.rg.location
  vnet_address_space      = ["10.0.0.0/16"]

  # Optional blocks
  create_security_groups  = true
  create_route_tables     = true

  # Network Security Groups (only used if create_security_groups = true)
  security_groups = [
    {
      name = "allow-all"                  # must match security_group in subnets below
      security_rules = [
        {
          name                       = "Allow-ingress"   
          priority                   = 200
          direction                  = "Inbound"   # Inbound | Outbound
          access                     = "Allow"     # Allow | Deny
          protocol                   = "*"         # "*" | "Tcp" | "Udp" | "Icmp" (provider-dependent)
          source_port_range          = "*"         # "*" | "80" | "100-200" | "*/200" | "200/*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "Allow-ingress-2"
          priority                   = 210
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }
  ]

  # Route tables (only used if create_route_tables = true)
  routes = [
    {
      name    = "default-route"      # must match route_table in subnets below
      details = [
        {
          name                   = "default-route"
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"     # VirtualNetworkGateway | VnetLocal | Internet | VirtualAppliance | None
          next_hop_in_ip_address = "10.0.0.1"   # IP of the virtual appliance
        }
      ]
    }
  ]

  # Subnets (associate by the *names* above)
  subnets = [
    {
      name              = "subnet-1"
      range             = ["10.0.210.0/26"]
      private           = true
      security_group    = "allow-all"                 # must match security_group name above
      route_table       = "default-route"             # must match route_table name above
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"] # Service endpoints
      # Example delegation for Azure Database for PostgreSQL Flexible Server
      delegation = {
        name = "psql_delegation"
        service_delegation = {
          name    = "Microsoft.DBforPostgreSQL/flexibleServers"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    }
  ]

  # Default tags applied to all resources
  default_tags = {
    environment = "production"
    app         = "networking"
    # ...additional tags as needed
  }
}