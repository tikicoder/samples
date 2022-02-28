variable "global_settings" {
  type = object({
    identifier = string
    tags = map(string)
  })
}

variable "settings_vpc" {
  type = object({
    id = string
    vpc_name = string
  })
}


variable "settings" {
  type = object({
    skip_resource = bool
    tags = optional(map(string))
    name = string

    
    vpc_id = string
    
    # propagating_vgws = optional(string)
    
    # I do not want this to manage routes
    # routesTables = optional(object({
    #   cidr_block  = string
    #   ipv6_cidr_block  = optional(string)
    #   destination_prefix_list_id = optional(string)

    #   carrier_gateway_id = optional(string)
    #   egress_only_gateway_id = optional(string)
    #   gateway_id = optional(string)
    #   instance_id = optional(string)
    #   local_gateway_id = optional(string)
    #   nat_gateway_id = optional(string)
    #   network_interface_id = optional(string)
    #   transit_gateway_id = optional(string)
    #   vpc_endpoint_id = optional(string)
    #   vpc_peering_connection_id = optional(string)
    # }))
        
  })
}

