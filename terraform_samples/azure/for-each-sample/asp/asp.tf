locals {
  keys = {
    for item in keys(var.settings):
      "_${item}" => item
  }
  resource_group_name_asp = var.settings[keys(var.settings)[0]].resource_group_name_asp
  resource_group_name_function = var.settings[keys(var.settings)[0]].resource_group_name_function
  identifiers = {
    for key in local.keys:
      key => length(var.global_settings[key].identifier) > 0 ?"-${var.global_settings[key].identifier}" : ""
  }
}

resource "azurerm_app_service_plan" "app_service_plan_windows" {
  for_each            = local.keys
  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-plan-windows"
  resource_group_name = local.resource_group_name_asp
  location            = var.global_settings[each.value].location
  kind                = "Windows" # Windows | Linux | elastic | FunctionApp
  #is_xenon = true
  reserved            = "false" # This must be set to true if kind = "Linux"

  sku {
    tier = var.settings[each.value].windows_app_tier
    size = var.settings[each.value].windows_app_size
  }

  tags = {
    environment = var.global_settings[each.value].environment
  }
}

resource "azurerm_app_service_plan" "app_service_plan_function" {
  for_each            = local.keys
  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-plan-function"
  resource_group_name = local.resource_group_name_function
  location            = azurerm_app_service_plan.app_service_plan_windows[each.key].location
  kind                = "Windows" # Windows | Linux | elastic | FunctionApp
  reserved            = "false" # This must be set to true if kind = "Linux"

  sku {
    tier = var.settings[each.value].function_app_tier
    size = var.settings[each.value].function_app_size
  }

  tags = {
    environment = var.global_settings[each.value].environment
  }
}
