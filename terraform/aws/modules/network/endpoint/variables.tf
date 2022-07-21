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

variable "security_group_ids" {
  type = list(string)
}

variable "subnet_ids" {
  type = list(string)
}

variable "route_table_ids" {
  type = list(string)
}

variable "settings" {
  type = object({
    
    tags = optional(map(any))      
    skip_resource = bool

    name = string
    service_name = string
    vpc_endpoint_type = string
    security_group_ids = optional(list(string))
    subnet_ids = optional(list(string))
    private_dns_enabled = optional(bool)

    route_table_ids = optional(list(string))
  })
}

