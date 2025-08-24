# Variables for the networking module

variable "app_name" {
  description = "Name of the application or project"
  type        = string
}

variable "azure_env" {
  description = "Azure environment (e.g. dev, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the existing Azure Resource Group into which resources will be deployed"
  type        = string
}

variable "resource_group_location" {
  description = "Azure location for the Resource Group (e.g. eastus, westeurope)"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "List of subnet configurations"
  type = list(object({
    name              = string
    range             = list(string)
    private           = optional(bool, false)
    security_group    = optional(string)
    route_table       = optional(string)
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }), null)
  }))
}

variable "security_groups" {
  description = "List of network security group definitions"
  type = list(object({
    name           = string
    security_rules = list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))
  }))
  default = []
}

variable "routes" {
  description = "List of route table definitions"
  type = list(object({
    name    = string
    details = list(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    }))
  }))
  default = []
}

variable "create_security_groups" {
  description = "Whether to create network security groups"
  type        = bool
  default     = true
}

variable "create_route_tables" {
  description = "Whether to create route tables"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of default tags to apply to all resources"
  type        = map(string)
  default     = {}
}