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
