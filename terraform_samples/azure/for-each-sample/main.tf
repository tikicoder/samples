locals {  
  settings_app_insights = {
    for item in keys(var.settings_app_insights):
      item => {
          resource_group_name = module.resource-groups.app_insights_resource_group_name
      }
  }

  settings_networking = {
    for item in keys(var.settings_networking):
      item => merge(var.settings_networking[item], { 
        resource_group_name = module.resource-groups.network_resource_group_name
        shared_key = var.shared_key, 
        vnet_gateway_base64_certificate = var.base64_certificate,
        main_vpn_gateway_ip_configuration_name = length(var.settings_networking[item].main_vpn_gateway_ip_configuration_name) < 1 ? "vnetGatewayConfig" : var.settings_networking[item].main_vpn_gateway_ip_configuration_name
      })
  }  
#Add subnet ID to see if that will give the full path
#ex.
#/subscriptions/d617d0fc-9c11-44b8-98fa-9ea194c4322b/resourceGroups/test-qa-network-rg/providers/microsoft.network/virtualNetworks/test-qa-vnet/subnets/test-qa-function-subnet
  settings_security = {
    for item in keys(var.settings_security):
      item => merge(var.settings_security[item], { 
        resource_group_name         = module.resource-groups.security_resource_group_name
        resource_group_name_network = module.resource-groups.network_resource_group_name
        virtual_network_name        = length(keys(module.networking.virtual_network_name)) < 1 ? "" : module.networking.virtual_network_name[keys(module.networking.virtual_network_name)[index(keys(var.settings_networking), item)]][0],
        subnet_asp_name             = length(keys(module.networking.subnet_asp_name)) < 1 ? "" : module.networking.subnet_asp_name[keys(module.networking.subnet_asp_name)[index(keys(var.settings_networking), item)]][0],
        subnet_asp_id               = length(keys(module.networking.subnet_asp_id)) < 1 ? "" : module.networking.subnet_asp_id[keys(module.networking.subnet_asp_id)[index(keys(var.settings_networking), item)]][0],
        subnet_function_name        = length(keys(module.networking.subnet_function_name)) < 1 ? "" : module.networking.subnet_function_name[keys(module.networking.subnet_function_name)[index(keys(var.settings_networking), item)]][0],
        subnet_function_id          = length(keys(module.networking.subnet_function_id)) < 1 ? "" : module.networking.subnet_function_id[keys(module.networking.subnet_function_id)[index(keys(var.settings_networking), item)]][0],
        app_gateway_ip              = length(keys(module.networking.app_gateway_ip)) < 1 ? "" : module.networking.app_gateway_ip[keys(module.networking.app_gateway_ip)[index(keys(var.settings_networking), item)]][0],
        subnet_id                   = length(keys(module.networking.subnet_id)) < 1 ? "" : module.networking.subnet_id[keys(module.networking.subnet_id)[index(keys(var.settings_networking), item)]][0],
        tenant_id                   = var.tenant_id,
        kv_access_object_id         = var.kv_access_object_id,
        kv_access_app_id            = var.kv_access_app_id,
        subscription_id             = var.subscription_id
      })
  }

  settings_data = {
    for item in keys(var.settings_data):
      item => merge(var.settings_data[item], { 
        resource_group_name = module.resource-groups.data_resource_group_name
        sql_server_username = var.sql_server_username, 
        sql_server_password = var.sql_server_password
      })
  }

  settings_apim = {
    for item in keys(var.settings_apim):
      item => merge(var.settings_apim[item], {
          resource_group_name = module.resource-groups.apim_resource_group_name
      })
  }

  settings_asp = {
    for item in keys(var.settings_asp):
      item => merge(var.settings_asp[item], {
          resource_group_name_asp = module.resource-groups.windows_asp_resource_group_name
          resource_group_name_function = module.resource-groups.function_asp_resource_group_name
      })
  }

  settings_service_bus = {
    for item in keys(var.settings_service_bus):
      item => merge(var.settings_service_bus[item], {
          resource_group_name = module.resource-groups.service_bus_resource_group_name
      })
  }

  settings_search = {
    for item in keys(var.settings_search):
      item => merge(var.settings_search[item], {
          resource_group_name = module.resource-groups.search_resource_group_name
      })
  }
  
}

module "resource-groups" {
  source = "./resource-groups"

  global_settings = var.global_settings
}

module "app-insights" {
  source = "./app-insights"

  global_settings = var.global_settings
  settings = local.settings_app_insights
}

module "networking" {
  source = "./networking"

  global_settings = var.global_settings
  settings = local.settings_networking
}

module "security" {
  source = "./security"

  global_settings = var.global_settings
  settings = local.settings_security
}

module "apim" {
  source = "./apim"

  global_settings = var.global_settings
  settings = local.settings_apim
}

module "asp" {
  source = "./asp"

  global_settings = var.global_settings
  settings = local.settings_asp
}

module "data" {
  source = "./data"

  global_settings = var.global_settings
  settings = local.settings_data
}

module "service-bus" {
  source = "./service-bus"

  global_settings = var.global_settings
  settings = local.settings_service_bus
}

module "search" {
  source = "./search"

  global_settings = var.global_settings
  settings = local.settings_search
}
