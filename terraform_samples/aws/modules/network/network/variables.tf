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

variable "route_table" {
  type = map(string)
}

variable "settings" {
  type = object({
    tags = optional(map(any))

    vpc_id = string
    subnets = map(object({
        skip_resource = bool
        name = string
        cidr_block = string
        route_table = string
    }))

    public_subnets = optional(list(string))
      
    nat_subnets = optional(list(object({
        public = string
        private = string
    })))
  })
}

