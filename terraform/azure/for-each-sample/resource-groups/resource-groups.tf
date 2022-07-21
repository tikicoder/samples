locals {
  environment   = var.global_settings[keys(var.global_settings)[0]].environment
  location      = var.global_settings[keys(var.global_settings)[0]].location
}

resource "azurerm_resource_group" "network_rg" {
  name = "test-${local.environment}-network-rg"
  location = local.location

  tags = {
    environment = local.environment
  }
}

resource "azurerm_resource_group" "security_rg" {
  name = "test-${local.environment}-security-rg"
  location = local.location

  tags = {
    environment = local.environment
  }
}

resource "azurerm_resource_group" "apim_rg" {
  name = "test-${local.environment}-apim-rg"
  location = local.location

  tags = {
    environment = local.environment
  }
}

resource "azurerm_resource_group" "function_asp_rg" {
  name = "test-${local.environment}-function-asp-rg"
  location = local.location

  tags = {
    environment = local.environment
  }
}

resource "azurerm_resource_group" "windows_asp_rg" {
  name = "test-${local.environment}-windows-asp-rg"
  location = local.location

  tags = {
    environment = local.environment
  }
}

resource "azurerm_resource_group" "data_rg" {
  name = "test-${local.environment}-data-rg"
  location = local.location

  tags = {
    environment = local.environment
  }
}

resource "azurerm_resource_group" "app_insights_rg" {
  name = "test-${local.environment}-app-insights-rg"
  location = local.location

  tags = {
    environment = local.environment
  }
}

resource "azurerm_resource_group" "service_bus_rg" {
  name = "test-${local.environment}-servicebus-rg"
  location = local.location

  tags = {
    environment = local.environment
  }
}

resource "azurerm_resource_group" "search_rg" {
  name     = "test-${local.environment}-search-rg"
  location = local.location

  tags = {
    environment = local.environment
  }
}
