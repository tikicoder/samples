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
  }))
}

