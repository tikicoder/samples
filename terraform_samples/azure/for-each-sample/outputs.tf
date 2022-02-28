output "windows_asp_id" {
  value = {
    for key in keys(module.asp.windows_asp_id):
      key => module.asp.windows_asp_id[key]...
  }
}

output "function_asp_id" {
  value = {
    for key in keys(module.asp.function_asp_id):
      key => module.asp.function_asp_id[key]...
  }
}

output "appinsights_instrumentation_key" {
  value = {
    for key in keys(module.app-insights.instrumentation_key):
      key => module.app-insights.instrumentation_key[key]...
  }
}


output "services_service_bus_namespace_name" {
  value = {
    for key in keys(module.service-bus.services_namespace_name):
      key => module.service-bus.services_namespace_name[key]...
  }
}

output "integration_service_bus_namespace_name" {
  value = {
    for key in keys(module.service-bus.integration_namespace_name):
      key => module.service-bus.integration_namespace_name[key]...
  }
}

output "service_bus_resource_group_name" {
  value = {
    for key in keys(module.service-bus.service_bus_resource_group_name):
      key => module.service-bus.service_bus_resource_group_name[key]...
  }
}

output "search_service_name" {
  value = {
    for key in keys(module.search.search_service_name):
      key => module.search.search_service_name[key]...
  }
}

output "search_service_key" {
  value = {
    for key in keys(module.search.search_service_key):
      key => module.search.search_service_key[key]...
  }
}

output "sql_server_fqdn" {
  value = {
    for key in keys(module.data.sql_server_fqdn):
      key => module.data.sql_server_fqdn[key]...
  }
}

output "sql_server_name" {
  value = {
    for key in keys(module.data.sql_server_name):
      key => module.data.sql_server_name[key]...
  }
}

