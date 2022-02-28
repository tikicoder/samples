variable "global_settings" {
  type = map(object({
    environment = string
    location = string
    identifier = string
  }))
}