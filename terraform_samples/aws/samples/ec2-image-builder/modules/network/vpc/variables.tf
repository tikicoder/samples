variable "global_settings" {
  type = map(object({
    identifier = string
  }))
}

variable "settings" {
  type = map(object({
    skip_resource = bool
    tags = map(any)
    
    name = string
    cidr_block = string
    
    enable_dns_support = bool
    enable_dns_hostnames = bool

  }))
}

