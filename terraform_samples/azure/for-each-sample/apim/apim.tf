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
}

resource "azurerm_api_management" "apim" {
  for_each            = local.keys
  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-apim"
  resource_group_name = local.resource_group_name
  location            = var.global_settings[each.value].location

  publisher_name      = var.settings[each.value].publisher_name
  publisher_email     = var.settings[each.value].publisher_email
  sku_name            = var.settings[each.value].sku_name

  tags = {
    environment = var.global_settings[each.value].environment
  }
}

resource "azurerm_api_management_property" "authService" {
  for_each            = local.keys
  name                = "authservice${local.identifiers[each.value]}"
  resource_group_name = azurerm_api_management.apim[each.key].resource_group_name
  api_management_name = azurerm_api_management.apim[each.key].name
  display_name        = "AuthService"
  value               = "https://test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-auth-app-service.azurewebsites.net/"
}

resource "azurerm_api_management_property" "crmService" {
  for_each            = local.keys
  name                = "crmservice${local.identifiers[each.value]}"
  resource_group_name = azurerm_api_management.apim[each.key].resource_group_name
  api_management_name = azurerm_api_management.apim[each.key].name
  display_name        = "CrmService"
  value               = "https://test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-crm-app-service.azurewebsites.net/"
}
