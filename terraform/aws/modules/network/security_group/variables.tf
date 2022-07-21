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
    tags = optional(map(any))

    vpc_id = string
    name = string
    description = optional(string)
    
    # work in progress
    rules = optional(list(object(
      {
        type = string
        protocol = string
        from_port = number
        to_port = number
      }
    )))
        
  })
}

