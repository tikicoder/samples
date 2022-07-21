global_settings = {
    northcentralus = {
      environment = "qa"
      location = "northcentralus"
      identifier = ""
    }
}

settings_apim = {
    northcentralus = {
      resource_group_name = ""
      publisher_name = "Nerdery"
      publisher_email = "test@nerdery.com"
      sku_name = "Developer_1"
    }
}

settings_app_insights = {
    northcentralus = {
      resource_group_name = ""
    }
}

settings_asp = {
    northcentralus = {
      resource_group_name_asp = ""
      resource_group_name_function = ""
      windows_app_tier = "Standard"
      windows_app_size = "S1"
      function_app_tier = "Standard"
      function_app_size = "S1"
    }
}

settings_data = {
    northcentralus = {
      resource_group_name = ""
      
      sql_server_username = ""
      sql_server_password = ""

      elastic_pool_max_db_size_gb = 50
      elastic_pool_sku_name = "GP_Gen5"
      elastic_pool_sku_tier = "GeneralPurpose"
      elastic_pool_sku_family = "Gen5"
      elastic_pool_sku_capacity = 2
      elastic_pool_per_database_settings_min = 0.25
      elastic_pool_per_database_settings_max = 1

      enable_failover_group = false
      failover_grace_minutes = 60
    }
}

settings_networking = {
    northcentralus = {
      resource_group_name = ""

      waf_subnet_address_space = "172.20.12.0/24"
      waf_enabled = false

      vnet_address_space = "172.20.0.0/16"
      gateway_subnet_address_space = "172.20.254.0/24"
      apim_subnet_address_space = "172.20.13.0/24"
      cache_subnet_address_space = "172.20.14.0/24"
      asp_subnet_address_space = "172.20.11.0/24"
      function_subnet_address_space = "172.20.15.0/24"
      data_replication_address_space = "172.20.18.0/24"

      on_prem_address_ranges = ["10.0.0.0/24"]
      shared_key = ""
      
      vnet_gateway_certificate_name = "AppServiceCertificate.cer"
      vnet_gateway_base64_certificate = ""
      main_vpn_gateway_ip_configuration_name = "default"
    }
}

settings_search = {
    northcentralus = {
      resource_group_name = ""
      sku = "free"
    }
}

settings_security = {
    northcentralus = {
      resource_group_name = ""      
      resource_group_name_network = ""
      virtual_network_name = ""
      subnet_asp_name = ""
      subnet_asp_id = ""
      subnet_function_name = ""
      subnet_function_id = ""
      waf_enabled = false
      app_gateway_ip = ""
      subnet_id = ""
      tenant_id = ""
      kv_access_object_id = ""
      kv_access_app_id = ""
      subscription_id = ""
    }
}

settings_service_bus = {
    northcentralus = {
      resource_group_name = ""
      servicebus_sku = "Standard"
    }
}
