variable "global_settings" {
  type = map(object({
    identifier = string
  }))
}

variable "settings" {
  type = map(object({
    skip_resource = bool
    tags = map(any)

    vpc_id = string
    routesTables = map(any)
        
  }))
}

