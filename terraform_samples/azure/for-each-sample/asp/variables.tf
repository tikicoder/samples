variable "global_settings" {
  type = map(object({
    environment = string
    location = string
    identifier = string
  }))
}

variable "settings" {
  type = map(object({
    resource_group_name_asp = string
    resource_group_name_function = string
    windows_app_tier = string
    windows_app_size = string
    function_app_tier = string
    function_app_size = string
  }))
}
