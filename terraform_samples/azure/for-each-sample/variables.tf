variable "global_settings" {
  type = map(object({
    environment = string
    location = string
    identifier = string
  }))
}

variable "settings_apim" {
  type = map(object({
    resource_group_name = string
    publisher_name = string
    publisher_email = string
    sku_name = string
  }))
}

variable "settings_app_insights" {
  type = map(object({
    resource_group_name = string
  }))
}

variable "settings_asp" {
  type = map(object({
    resource_group_name_asp = string
    resource_group_name_function = string
    windows_app_tier = string
    windows_app_size = string
    function_app_tier = string
    function_app_size = string
  }))
}

variable "settings_data" {
  type = map(object({
    resource_group_name = string
    
    sql_server_username = string
    sql_server_password = string

    elastic_pool_max_db_size_gb = number
    elastic_pool_sku_name = string
    elastic_pool_sku_tier = string
    elastic_pool_sku_family = string
    elastic_pool_sku_capacity = number
    elastic_pool_per_database_settings_min = number
    elastic_pool_per_database_settings_max = number

    enable_failover_group = bool
    failover_grace_minutes = number
  }))
}

variable "settings_networking" {
  type = map(object({
    resource_group_name = string
    waf_subnet_address_space = string
    waf_enabled = bool

    vnet_address_space = string
    gateway_subnet_address_space = string
    apim_subnet_address_space = string
    cache_subnet_address_space = string
    asp_subnet_address_space = string
    function_subnet_address_space = string
    data_replication_address_space = string
    on_prem_address_ranges = list(string)
    shared_key = string
    vnet_gateway_certificate_name = string
    vnet_gateway_base64_certificate = string
    main_vpn_gateway_ip_configuration_name = string
  }))
}

variable "settings_search" {
  type = map(object({
    resource_group_name = string
    sku = string
  }))
}

variable "settings_security" {
  type = map(object({
    resource_group_name = string
    resource_group_name_network = string
    virtual_network_name = string
    subnet_asp_name = string
    subnet_asp_id = string
    subnet_function_name = string
    subnet_function_id = string
    waf_enabled = bool
    app_gateway_ip = string
    subnet_id = string
    tenant_id = string
    kv_access_object_id = string
    kv_access_app_id = string
    subscription_id = string
  }))
}

variable "settings_service_bus" {
  type = map(object({
    resource_group_name = string
    servicebus_sku = string
  }))
}

variable "shared_key" {
  type = string
}
variable "base64_certificate" {
  type = string
}

variable "tenant_id" {
  type = string
}
variable "kv_access_object_id" {
  type = string
}
variable "kv_access_app_id" {
  type = string
}
variable "subscription_id" {
  type = string
}


variable "sql_server_username" {
  type = string
}
variable "sql_server_password" {
  type = string
}