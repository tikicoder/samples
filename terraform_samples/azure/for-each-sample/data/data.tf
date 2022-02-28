locals {
  keys = {
    for item in keys(var.settings):
      "_${item}" => item
  }

  keys_failover = {
    for item in keys(var.settings):
      "_${item}" => item
      if item != keys(var.settings)[0]
  }

  resource_group_name = var.settings[keys(var.settings)[0]].resource_group_name
  identifiers = {
    for key in local.keys:
      key => length(var.global_settings[key].identifier) > 0 ?"-${var.global_settings[key].identifier}" : ""
  }
  enable_failover_group = var.settings[keys(var.settings)[0]].enable_failover_group && length(keys(local.keys_failover)) > 0
}

resource "azurerm_sql_server" "server" {
  for_each                      = local.keys
  name                          = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-sql-server"
  resource_group_name           = local.resource_group_name
  location                      = var.global_settings[each.value].location

  version                       = "12.0"
  administrator_login           = var.settings[each.value].sql_server_username
  administrator_login_password  = var.settings[each.value].sql_server_password

  tags = {
    environment = var.global_settings[each.value].environment
  }
}

resource "azurerm_sql_firewall_rule" "allow_azure_services" {
  for_each            = local.keys
  name                = "AllowAzureServices${local.identifiers[each.value]}"
  resource_group_name = azurerm_sql_server.server[each.key].resource_group_name
  server_name         = azurerm_sql_server.server[each.key].name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_data_factory" "data_factory" {
  for_each            = local.keys
  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-data-factory"
  resource_group_name = azurerm_sql_server.server[each.key].resource_group_name
  location            = azurerm_sql_server.server[each.key].location

  tags = {
    environment = var.global_settings[each.value].environment
  }
}

resource "azurerm_mssql_elasticpool" "elasticpool" {
  for_each            = local.keys
  name                = "${azurerm_sql_server.server[each.key].name}${local.identifiers[each.value]}-pool"
  resource_group_name = azurerm_sql_server.server[each.key].resource_group_name
  location            = azurerm_sql_server.server[each.key].location
  server_name         = azurerm_sql_server.server[each.key].name
  max_size_gb         = var.settings[each.value].elastic_pool_max_db_size_gb

  sku {
    name     = var.settings[each.value].elastic_pool_sku_name
    tier     = var.settings[each.value].elastic_pool_sku_tier
    family   = var.settings[each.value].elastic_pool_sku_family
    capacity = var.settings[each.value].elastic_pool_sku_capacity
  }

  per_database_settings {
    min_capacity = var.settings[each.value].elastic_pool_per_database_settings_min
    max_capacity = var.settings[each.value].elastic_pool_per_database_settings_max
  }
}

resource "azurerm_sql_failover_group" "sql_failover_group" {
  for_each            = local.enable_failover_group ? local.keys_failover : { }

  name                = "${azurerm_sql_server.server[each.key].name}-sql-failover"
  resource_group_name = azurerm_sql_server.server[each.key].resource_group_name
  server_name         = azurerm_sql_server.server[keys(var.settings)[0]].name
  databases           = [azurerm_mssql_elasticpool.elasticpool[each.key].id]
  partner_servers {
    id = azurerm_sql_server.server[keys(local.keys)[0]].id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = var.settings[each.value].failover_grace_minutes
  }
}