output "instrumentation_key" {
  value =  {
    for key in keys(azurerm_application_insights.app_insights):
      key => azurerm_application_insights.app_insights[key].instrumentation_key...
  }
}