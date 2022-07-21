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

resource "azurerm_search_service" "search_service" {
  for_each            = local.keys
  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-search"
  resource_group_name = local.resource_group_name
  location            = var.global_settings[each.value].location
  sku                 = var.settings[each.value].sku

  tags = {
    environment = var.global_settings[each.value].environment
  }
}