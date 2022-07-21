variable "global_settings" {
  type = object(
    {
      identifier = string
      tags = map(string)
    }
  )
}

variable "settings" {
  type = object({   

    skip_resource = bool
    tags = optional(map(string))
    name = string
    
    
    cidr_block = string
    
    enable_dns_support = optional(bool)
    enable_dns_hostnames = optional(bool)

    enable_classiclink = optional(bool)
    enable_classiclink_dns_support = optional(bool)

    enable_classiclink_dns_support = optional(bool)

    assign_generated_ipv6_cidr_block = optional(bool)

  })
}

