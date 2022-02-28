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
    waf_subnet_address_space = string
    waf_enabled = bool

    vnet_address_space = string
    gateway_subnet_address_space = string
    apim_subnet_address_space = string
    cache_subnet_address_space = string
    asp_subnet_address_space = string
    function_subnet_address_space = string
    on_prem_address_ranges = list(string)
    shared_key = string
    data_replication_address_space = string
    vnet_gateway_certificate_name = string
    vnet_gateway_base64_certificate = string
    main_vpn_gateway_ip_configuration_name = string
  }))
}