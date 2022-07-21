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
    name = string
    subnets = map(any)

    enableInternetGatway = bool
    publicSubnets = list(string)
    
    enableNat = bool
    natSubnets = list(object({
      publicSubnet = string
      privateSubnet = string
    }))

  }))
}

variable "routeTables" {
  type = map(any)
}

