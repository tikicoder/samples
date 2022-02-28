variable "global_settings" {
  type = map(object({
    identifier = string
  }))
}

variable "settings" {
  type = map(object({
    skip_resource = bool
    tags = map(any)


    ssmParams = list(object({
      name = string
      type = string
      value = string
    }))
  }))
}

variable "ssmParamters_secure" {
  type = map(object({
    ssmParams = map(string)

  }))
}

