locals {
  keys = {
    for item in keys(var.settings):
      "_${item}" => item
  }
  resource_group_name = var.settings[keys(var.settings)[0]].resource_group_name
  identifiers = {
    for key in local.keys:
      key => length(var.global_settings[key].identifier) > 0 ?"-${var.global_settings[key].identifier}" : ""
  }
  waf_enabled = var.settings[keys(var.settings)[0]].waf_enabled
}

resource "azurerm_virtual_network" "main_vnet" {
  for_each            = local.keys

  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-vnet"
  resource_group_name = local.resource_group_name
  address_space       = [var.settings[each.value].vnet_address_space]
  location            = var.global_settings[each.value].location

  tags = {
    environment = var.global_settings[each.value].environment
  }
}

resource "azurerm_subnet" "gateway_subnet" {
  for_each              = local.keys

  name                  = "GatewaySubnet"
  resource_group_name   = azurerm_virtual_network.main_vnet[each.key].resource_group_name
  virtual_network_name  = azurerm_virtual_network.main_vnet[each.key].name
  address_prefix        = var.settings[each.value].gateway_subnet_address_space
  enforce_private_link_endpoint_network_policies = false
}

resource "azurerm_subnet" "apim_subnet" {
  for_each              = local.keys

  name                  = "test-${var.global_settings[each.value].environment}-apim-subnet"
  resource_group_name   = azurerm_virtual_network.main_vnet[each.key].resource_group_name
  virtual_network_name  = azurerm_virtual_network.main_vnet[each.key].name
  address_prefix        = var.settings[each.value].apim_subnet_address_space
  enforce_private_link_endpoint_network_policies = false
}

resource "azurerm_subnet" "cache_subnet" {
  for_each              = local.keys

  name                  = "test-${var.global_settings[each.value].environment}-cache-subnet"
  resource_group_name   = azurerm_virtual_network.main_vnet[each.key].resource_group_name
  virtual_network_name  = azurerm_virtual_network.main_vnet[each.key].name
  address_prefix        = var.settings[each.value].cache_subnet_address_space
  enforce_private_link_endpoint_network_policies = false
}

resource "azurerm_subnet" "asp_subnet" {
  for_each              = local.keys

  name                  = "test-${var.global_settings[each.value].environment}-asp-subnet"
  resource_group_name   = azurerm_virtual_network.main_vnet[each.key].resource_group_name
  virtual_network_name  = azurerm_virtual_network.main_vnet[each.key].name
  address_prefix        = var.settings[each.value].asp_subnet_address_space
  service_endpoints     = ["Microsoft.KeyVault"]
  enforce_private_link_endpoint_network_policies = false

  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ] 
    }
  }
}

resource "azurerm_subnet" "data_replication_subnet" {
  for_each              = local.keys
  name                  = "test-${var.global_settings[each.value].environment}-data-replication-subnet"
  resource_group_name   = azurerm_virtual_network.main_vnet[each.key].resource_group_name
  virtual_network_name  = azurerm_virtual_network.main_vnet[each.key].name
  address_prefix        = var.settings[each.value].data_replication_address_space
  service_endpoints = ["Microsoft.KeyVault"]
  enforce_private_link_endpoint_network_policies = false

  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ] 
    }
  }
}

resource "azurerm_subnet" "function_subnet" {
  for_each              = local.keys
  name                  = "test-${var.global_settings[each.value].environment}-function-subnet"
  resource_group_name   = azurerm_virtual_network.main_vnet[each.key].resource_group_name
  virtual_network_name  = azurerm_virtual_network.main_vnet[each.key].name
  address_prefix        = var.settings[each.value].function_subnet_address_space
  service_endpoints     = ["Microsoft.KeyVault"]
  enforce_private_link_endpoint_network_policies = false

  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ] 
    }
  }
}

resource "azurerm_public_ip" "vpn_gateway_ip" {
  for_each            = local.keys

  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-vpn-gateway-ip"
  location            = azurerm_virtual_network.main_vnet[each.key].location
  resource_group_name = azurerm_virtual_network.main_vnet[each.key].resource_group_name
  allocation_method   = "Dynamic"

  tags = {
    environment = var.global_settings[each.value].environment
  }
}

resource "azurerm_virtual_network_gateway" "main_vpn_gateway" {
  for_each            = local.keys

  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-vpn-gw"
  resource_group_name = azurerm_virtual_network.main_vnet[each.key].resource_group_name
  location            = azurerm_virtual_network.main_vnet[each.key].location
  type                = "Vpn"
  sku                 = "VpnGw1"
  vpn_type            = "RouteBased"
  enable_bgp          = false

  ip_configuration {
    name                  = var.settings[each.value].main_vpn_gateway_ip_configuration_name
    subnet_id             = azurerm_subnet.gateway_subnet[each.key].id
    public_ip_address_id  = azurerm_public_ip.vpn_gateway_ip[each.key].id
    private_ip_address_allocation = "Dynamic"
  }

  vpn_client_configuration {
    address_space         = var.settings[each.value].on_prem_address_ranges
    vpn_client_protocols  = ["OpenVPN"]
    
    root_certificate {
      name              = var.settings[each.value].vnet_gateway_certificate_name 
      public_cert_data  = var.settings[each.value].vnet_gateway_base64_certificate 
    }


    
  }

  tags = {
    environment = var.global_settings[each.value].environment
  }
}

resource "azurerm_local_network_gateway" "main_local_gateway" {
  for_each            = local.keys
  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-local-gw"
  resource_group_name = azurerm_virtual_network.main_vnet[each.key].resource_group_name
  location            = azurerm_virtual_network.main_vnet[each.key].location
  gateway_address     = "70.34.187.122"
  address_space       = var.settings[each.value].on_prem_address_ranges

  tags = {
    environment = var.global_settings[each.value].environment
  }
}

resource "azurerm_virtual_network_gateway_connection" "main_vpn_connection" {
  for_each                    = local.keys
  name                        = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-vpn-connection"
  resource_group_name         = azurerm_virtual_network.main_vnet[each.key].resource_group_name
  location                    = azurerm_virtual_network.main_vnet[each.key].location
  type                        = "IPsec"
  virtual_network_gateway_id  = azurerm_virtual_network_gateway.main_vpn_gateway[each.key].id
  local_network_gateway_id    = azurerm_local_network_gateway.main_local_gateway[each.key].id

  shared_key                  = var.settings[each.value].shared_key

  tags = {
    environment = var.global_settings[each.value].environment
  }
}

resource "azurerm_subnet" "app_gateway_subnet" {
  for_each            = local.waf_enabled ? local.keys : { }

  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-waf-subnet"
  resource_group_name = azurerm_virtual_network.main_vnet[each.key].resource_group_name
  virtual_network_name = azurerm_virtual_network.main_vnet[each.key].name
  address_prefix = var.settings[each.value].waf_subnet_address_space
  enforce_private_link_endpoint_network_policies = false
}

resource "azurerm_public_ip" "app_gateway_ip" {
  for_each            = local.waf_enabled ? local.keys : { }
  
  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-app-gateway-ip"
  location            = azurerm_virtual_network.main_vnet[each.key].location
  resource_group_name = azurerm_virtual_network.main_vnet[each.key].resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = var.global_settings[each.value].environment
  }
}
