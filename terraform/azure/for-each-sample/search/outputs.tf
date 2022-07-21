output "search_service_name" {
  value = {
    for key in keys(azurerm_search_service.search_service):
      key => azurerm_search_service.search_service[key].name...
  }
}

output "search_service_key" {
  value = {
    for key in keys(azurerm_search_service.search_service):
      key => azurerm_search_service.search_service[key].primary_key...
  }
}