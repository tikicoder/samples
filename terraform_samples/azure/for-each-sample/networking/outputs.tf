output "app_gateway_ip" {
  value = {
    for key in keys(azurerm_public_ip.app_gateway_ip):
      key => azurerm_public_ip.app_gateway_ip[key].id...
  }
}

output "subnet_id" {
  value = {
    for key in keys(azurerm_subnet.app_gateway_subnet):
      key => azurerm_subnet.app_gateway_subnet[key].id...
  }
}

output "virtual_network_name" {
  value = {
    for key in keys(azurerm_virtual_network.main_vnet):
      "${key}" => azurerm_virtual_network.main_vnet[key].name...
  }
}

output "subnet_asp_name" {
  value = {
    for key in keys(azurerm_subnet.asp_subnet):
      key => azurerm_subnet.asp_subnet[key].name...
  }
}

output "subnet_function_name" {
  value = {
    for key in keys(azurerm_subnet.function_subnet):
      key => azurerm_subnet.function_subnet[key].name...
  }
}

output "subnet_asp_id" {
  value = {
    for key in keys(azurerm_subnet.asp_subnet):
      key => azurerm_subnet.asp_subnet[key].id...
  }
}

output "subnet_function_id" {
  value = {
    for key in keys(azurerm_subnet.function_subnet):
      key => azurerm_subnet.function_subnet[key].id...
  }
}
