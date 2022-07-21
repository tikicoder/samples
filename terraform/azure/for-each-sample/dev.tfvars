global_settings = {
    northcentralus = {
      environment = "dev"
      location = "northcentralus"
      identifier = ""
    }
}

settings_apim = {
    northcentralus = {
      resource_group_name = ""
      resource_group_name_network = ""
      virtual_network_name = ""
      subnet_asp_name = ""
      subnet_asp_id = ""
      subnet_function_name = ""
      subnet_function_id = ""
      publisher_name = "Sample Publisher"
      publisher_email = "test@sample_publisher.com"
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

      waf_subnet_address_space = "172.19.2.0/24"
      waf_enabled = false

      vnet_address_space = "172.19.0.0/16"
      gateway_subnet_address_space = "172.19.255.0/24"
      apim_subnet_address_space = "172.19.3.0/24"
      cache_subnet_address_space = "172.19.4.0/24"
      asp_subnet_address_space = "172.19.1.0/24"
      function_subnet_address_space = "172.19.5.0/24"
      data_replication_address_space = "172.19.8.0/24"

      on_prem_address_ranges = ["10.0.0.0/24"]
      shared_key = ""
      
      vnet_gateway_certificate_name = "AppServiceCertificate.cer"
      vnet_gateway_base64_certificate = ""
      main_vpn_gateway_ip_configuration_name = "vnetGatewayConfig"
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
