output "service_bus_resource_group_name" {
  value = {
    for key in keys(azurerm_servicebus_namespace.service_namespace):
      "${key}" => azurerm_servicebus_namespace.service_namespace[key].resource_group_name...
  }
}

output "services_namespace_name" {
  value = {
    for key in keys(azurerm_servicebus_namespace.service_namespace):
      "${key}" => azurerm_servicebus_namespace.service_namespace[key].name...
  }
}

output "integration_namespace_name" {
  value = {
    for key in keys(azurerm_servicebus_namespace.integration_namespace):
      "${key}" => azurerm_servicebus_namespace.integration_namespace[key].name...
  }
}

