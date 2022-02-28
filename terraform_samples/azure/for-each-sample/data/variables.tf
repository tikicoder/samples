variable "global_settings" {
  type = map(object({
    environment = string
    location = string
    identifier = string
  }))
}

variable "settings" {
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

