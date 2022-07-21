variable "region" {
  type = string
  default = "us-east-1"
}

variable "global_settings" {
  type = map(object({
    identifier = string
  }))
}

variable "settings_vpc" {
  type = map(object({
    skip_resource = bool
    tags = map(any)
    
    name = string
    cidr_block = string
    
    enable_dns_support = bool
    enable_dns_hostnames = bool

  }))
}

variable "settings_routetable" {
  type = map(object({
    skip_resource = bool
    tags = map(any)

    routesTables = map(any)
        
  }))
}

variable "settings_securitygroup" {
  type = map(object({
    skip_resource = bool
    tags = map(any)

    securityGroups = map(any)
        
  }))
}

variable "settings_network" {
  type = map(object({
    skip_resource = bool
    tags = map(any)

    subnets = map(any)

    publicSubnets = list(string)
    
    natSubnets = list(object({
      publicSubnet = string
      privateSubnet = string
    }))

  }))
}

variable "settings_ec2ImageBuilder_network_endPoint" {
  type = map(object({
    skip_resource = bool
    tags = map(any)

    interfaceEndpoints = map(any)
    gatewayEndpoints = map(any)

  }))
}

variable "settings_ec2ImageBuilder_iam_role" {
  type = map(object({
    skip_resource = bool
    tags = map(any)

    roles = map(any)
  }))
}

variable "settings_ec2ImageBuilder_component" {
  type = map(object({
    skip_resource = bool
    tags = map(any)

    components = map(any)
  }))
}

variable "settings_ec2ImageBuilder_recipe" {
  type = map(object({
    skip_resource = bool
    tags = map(any)

    recipes = map(any)
  }))
}

variable "settings_ssmParamters" {
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

 variable "settings_ssmParamters_secure" {
   type = map(object({
     ssmParams = map(string)

   }))
 }


variable "settings_ec2ImageBuilder_pipeline" {
  type = map(object({
    skip_resource = bool
    tags = map(any)

    pipelines = list(object({
        image_recipe_arn = string
        name = string
    }))
    distribution_configuration = list(object({
        name = string
        description = string 
        distributions = list(object({
          region = string
          ami_distribution_configuration = object({
            ami_tags = map(string)
          })
        }))
    }))
    infrastructure_configuration = object({
        name = string
        description = string 
        instance_profile_name = string

        instance_types = list(string)
        security_group_ids = list(string)

        subnet_id = string

        terminate_instance_on_failure = bool

    })
  }))
}