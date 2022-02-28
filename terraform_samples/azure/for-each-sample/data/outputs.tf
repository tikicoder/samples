output "sql_server_fqdn" {
  value = {
    for key in keys(azurerm_sql_server.server):
      key => azurerm_sql_server.server[key]...
  } 
}

output "sql_server_name" {
  value = {
    for key in keys(azurerm_sql_server.server):
      key => azurerm_sql_server.server[key].name...
  } 
}

