locals {
  keys = {
    for item in keys(var.settings):
      "_${item}" => item
  }
  resource_group_name = var.settings[keys(var.settings)[0]].resource_group_name
  resource_group_name_network = var.settings[keys(var.settings)[0]].resource_group_name_network

  identifiers = {
    for key in local.keys:
      key => length(var.global_settings[key].identifier) > 0 ?"-${var.global_settings[key].identifier}" : ""
  }
  waf_enabled = var.settings[keys(var.settings)[0]].waf_enabled
}


resource "azurerm_network_security_group" "nsg" {
  for_each            = local.waf_enabled ? local.keys : { }
  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-nsg"
  resource_group_name = local.resource_group_name
  location            = var.global_settings[each.value].location

  tags = {
    environment = var.global_settings[each.value].environment
  }
}

resource "azurerm_network_security_rule" "deny_all" {
  for_each                      = local.waf_enabled ? local.keys : { }
  name                          = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-nsg-rule-deny-all"
  priority                      = 100
  direction                     = "Inbound"
  access                        = "Deny"
  protocol                      = "Tcp"
  source_port_range             = "*"
  destination_port_range        = "*"
  source_address_prefix         = "0.0.0.0/0"
  destination_address_prefix    = "0.0.0.0/0"
  resource_group_name           = azurerm_network_security_group.nsg[each.key].resource_group_name
  network_security_group_name   = azurerm_network_security_group.nsg[each.key].name
}

resource "azurerm_application_gateway" "waf" {
  for_each            = local.waf_enabled ? local.keys : { }
  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-waf"
  resource_group_name = local.resource_group_name
  location            = var.global_settings[each.value].location

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
    capacity = "1"
  }

  backend_address_pool {
    name = "defaultBackendPool"
  }

  backend_http_settings {
    cookie_based_affinity = "Disabled"
    name                  = "defaultHttpBackendSettings"
    port                  = "80"
    protocol              = "Http"
    request_timeout       = "10"
  }

  frontend_ip_configuration {
    name                  = "defaultFrontendConfig"
    public_ip_address_id  = var.settings[each.value].app_gateway_ip
  }

  frontend_port {
    name = "defaultPort"
    port = "80"
  }

  gateway_ip_configuration {
    name      = "defaultIpConfig"
    subnet_id = var.settings[each.value].subnet_id
  }

  http_listener {
    name                            = "defaultHttpListener"
    frontend_ip_configuration_name  = "defaultFrontendConfig"
    frontend_port_name              = "defaultPort"
    protocol                        = "Http"
  }

  request_routing_rule {
    name                        = "defaultRoutingRule"
    rule_type                   = "Basic"
    http_listener_name          = "defaultHttpListener"
    backend_address_pool_name   = "defaultBackendPool"
    backend_http_settings_name  = "defaultHttpBackendSettings"
  }

  waf_configuration {
    enabled = true
    firewall_mode = "Prevention"
    rule_set_type = "OWASP"
    rule_set_version = "3.1"
  }

  tags = {
    environment = var.global_settings[each.value].environment
  }
}

resource "azurerm_key_vault" "key_vault" {
  for_each            = local.keys
  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-kv"
  resource_group_name = local.resource_group_name
  location            = var.global_settings[each.value].location

  tenant_id           = var.settings[each.value].tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = var.settings[each.value].tenant_id
    object_id = var.settings[each.value].kv_access_object_id
    application_id = var.settings[each.value].kv_access_app_id

    certificate_permissions = ["backup","create","delete","deleteissuers","get","getissuers","import","list","listissuers","managecontacts","manageissuers","purge","recover","restore","setissuers","update"]
    key_permissions = ["backup","create","decrypt","delete","encrypt","get","import","list","purge","recover","restore","sign","unwrapKey","update","verify","wrapKey"]
    secret_permissions = ["backup","delete","get","list","purge","recover","restore","set"]
    storage_permissions = ["backup","delete","deletesas","get","getsas","list","listsas","purge","recover","regeneratekey","restore","set","setsas","update"]
  }

  network_acls {
    bypass = "AzureServices"
    default_action = "Deny"
    virtual_network_subnet_ids = [var.settings[each.value].subnet_asp_id, var.settings[each.value].subnet_function_id]
  }

  tags = {
    environment = var.global_settings[each.value].environment
  }
}
