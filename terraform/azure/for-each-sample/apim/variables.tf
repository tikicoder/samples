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
    publisher_name = string
    publisher_email = string
    sku_name = string
  }))
}
