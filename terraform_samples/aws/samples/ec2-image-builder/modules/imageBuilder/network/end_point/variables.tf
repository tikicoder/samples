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
    vpc_name = string

    interfaceEndpoints = map(any)
    gatewayEndpoints = map(any)

  }))
}


variable "routeTables" {
  type = map(any)
}

variable "securityGroups" {
  type = map(any)
}

variable "subnets" {
  type = map(any)
}

