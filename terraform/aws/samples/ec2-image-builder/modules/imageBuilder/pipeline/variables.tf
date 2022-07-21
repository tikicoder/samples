variable "global_settings" {
  type = map(object({
    identifier = string
  }))
}

variable "settings" {
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

variable "recipes" {
  type = map(any)
}

variable "subnets" {
  type = map(any)
}

variable "securityGroups" {
  type = map(any)
}

variable "iamRoles" {
  type = map(any)
}

