variable "region" {
  type = string
  default = "us-east-1"
}

variable "global_settings" {
  type = map(object({
    identifier = string
    tags = map(string)
  }))
}

variable "settings_network" {
  type = map(object({
    vpc = map(object({
      skip_resource = bool    
      name = string
      cidr_block = string
      
      enable_dns_support = optional(bool)
      enable_dns_hostnames = optional(bool)

      enable_classiclink = optional(bool)
      enable_classiclink_dns_support = optional(bool)

      enable_classiclink_dns_support = optional(bool)

      assign_generated_ipv6_cidr_block = optional(bool)

      tags = optional(map(string))
    }))

    route_table = map(object({
      skip_resource = bool
      tags =optional(map(string))
      name = string
      
      vpc_id = string
          
    }))

    security_group = map(object({
      skip_resource = bool
      tags = optional(map(any))

      vpc_id = string
      name = string
      description = optional(string)
      
      rules = optional(list(object(
        {
          type = string
          protocol = string
          from_port = number
          to_port = number
        }
      )))
          
    }))

    network = map(object({
      tags = optional(map(any))

      vpc_id = string

      subnets = map(object({
        skip_resource = bool
        name = string
        cidr_block = string
        route_table = string
      }))

      public_subnets = optional(list(string))
      
      nat_subnets = optional(list(object({
        public = string
        private = string
      })))
    }))    

    endpoint = optional(map(object({
    
      tags = optional(map(any))      
      skip_resource = bool
      vpc_id = string
      network = string

      endpoint = optional(map(object({
        name = string
        service_name = string
        vpc_endpoint_type = string
        security_group_ids = optional(list(string))
        subnet_ids = optional(list(string))
        private_dns_enabled = optional(bool)

        route_table_ids = optional(list(string))
      })))
    })))
  }))
}



