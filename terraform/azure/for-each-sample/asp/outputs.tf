output "windows_asp_id" {
  value = {
    for key in keys(azurerm_app_service_plan.app_service_plan_windows):
      key => azurerm_app_service_plan.app_service_plan_windows[key].id...
  }
}

output "function_asp_id" {
  value = {
    for key in keys(azurerm_app_service_plan.app_service_plan_function):
      key => azurerm_app_service_plan.app_service_plan_function[key].id...
  }
}
