output "api_management_id" {
  value =  {
    for key in keys(azurerm_api_management.apim):
      key => azurerm_api_management.apim[key].id...
  } 
}