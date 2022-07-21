locals {  
  keys = {
    for item in keys(var.settings):
      "_${item}" => item
  }
  identifiers = {
    for key in local.keys:
      key => length(var.global_settings[key].identifier) > 0 ?"-${var.global_settings[key].identifier}" : ""
  }
}

resource "azurerm_application_insights" "app_insights" {
  for_each            = local.keys
  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-app-insights"
  location            = var.global_settings[each.value].location
  resource_group_name = var.settings[each.value].resource_group_name
  application_type    = "other"

  tags = {
    environment = var.global_settings[each.value].environment
  }
}
