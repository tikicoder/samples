variable "global_settings" {
  type = map(object({
    identifier = string
  }))
}

variable "settings" {
  type = map(object({
    skip_resource = bool
    tags = map(any)

    recipes = map(any)
  }))
}

variable "component_arn" {
  type = map(any)
}


variable "component_bygeneralkey" {
  type = map(any)
}

