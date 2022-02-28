locals {
  keys = {
    for key in keys(var.settings):
      key => key
      if contains(keys(var.global_settings), key) && !var.settings[key].skip_resource
  }

  identifiers = {
    for key in local.keys:
      key => length(var.global_settings[key].identifier) > 0 ?"-${var.global_settings[key].identifier}" : ""
  }  

  securityGroups = {
    for key in keys(var.settings) : 
      key => distinct(flatten([
        for item in var.settings[key].infrastructure_configuration.security_group_ids :
          var.securityGroups["${key}:${item}"].id
      ]))
  }

  pipeline_keys = flatten([
    for key in keys(local.keys) : [
      for pipeline in var.settings[key].pipelines : {
        "key" = key
        "pipelineKey" = pipeline.name
        "pipeline" = pipeline
      }
    ]
  ])

  pipeline_keys_map = {
    for item in local.pipeline_keys:
      "${item.key}:${item.pipelineKey}" => {
        "key"       = item.key
        "pipelineKey" = item.pipelineKey
        "name"      = try(item.pipeline.name, item.pipelineKey)
        "pipeline"            = item.pipeline
        "distributionKey"     = "${item.key}:${try(item.pipeline.distribution, item.pipelineKey)}"
      }
  }

  distribution_keys = flatten([
    for key in keys(local.keys) : [
      for distribution in var.settings[key].distribution_configuration : {
        "key" = key
        "distributionKey" = distribution.name
        "distribution" = distribution
      }
    ]
  ])

  distribution_keys_map = {
    for item in local.distribution_keys:
      "${item.key}:${item.distributionKey}" => {
        "key"       = item.key
        "distributionKey" = item.distributionKey
        "name"      = try(item.distribution.name, item.distributionKey)
        "distribution" = item.distribution
      }
  }



}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/imagebuilder_distribution_configuration
resource "aws_imagebuilder_distribution_configuration" "ec2ImageBuilder_pipeline_distrabution" {
  for_each = local.distribution_keys_map

  tags = try(merge({
    Name = "Distribution-${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.ec2ibDistrabution"
  }, var.settings[each.value.key].tags), {
    Name = "Distribution-${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.ec2ibDistrabution"
  })

  name            = "Distribution-${each.value.key}-${each.value.distribution.name}${local.identifiers[each.value.key]}"
  description     = length(each.value.distribution.description) < 1 ? null :each.value.distribution.description


  dynamic "distribution" {
    for_each = tolist(each.value.distribution.distributions)

    content {
      region = distribution.value.region

      ami_distribution_configuration {
        ami_tags = try(merge({
          Name = "image-${each.value.name}-${distribution.value.region}-{{imagebuilder:buildVersion}}-{{ imagebuilder:buildDate }}"
        }, distribution.value.ami_distribution_configuration.ami_tags), {
          Name = "image-${each.value.name}-${distribution.value.region}-{{imagebuilder:buildVersion}}-{{ imagebuilder:buildDate }}"
        })

        name = "image-${each.value.name}-${distribution.value.region}-{{imagebuilder:buildVersion}}-{{ imagebuilder:buildDate }}"
      }
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/imagebuilder_infrastructure_configuration
resource "aws_imagebuilder_infrastructure_configuration" "ec2ImageBuilder_pipeline_infastructure" {
  for_each = var.settings

  tags = try(merge({
    Name = "${each.key}.${each.value.infrastructure_configuration.name}${local.identifiers[each.key]}.ec2ibInfastructure"
  }, var.settings[each.key].tags), {
    Name = "${each.key}.${each.value.infrastructure_configuration.name}${local.identifiers[each.key]}.ec2ibInfastructure"
  })

  name                          = "Infastructure-${each.key}-${each.value.infrastructure_configuration.name}${local.identifiers[each.key]}"
  description                   = length(each.value.infrastructure_configuration.description) < 1 ? null :each.value.infrastructure_configuration.description
  instance_profile_name         = var.iamRoles["${each.key}:${each.value.infrastructure_configuration.instance_profile_name}"].name
  instance_types                = each.value.infrastructure_configuration.instance_types
  
  security_group_ids            = local.securityGroups[each.key]
  subnet_id                     = var.subnets["${each.key}:${each.value.infrastructure_configuration.subnet_id}"].id
  terminate_instance_on_failure = each.value.infrastructure_configuration.terminate_instance_on_failure


}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/imagebuilder_image_pipeline
resource "aws_imagebuilder_image_pipeline" "ec2ImageBuilder_pipeline" {
  for_each = local.pipeline_keys_map

  name     = "Pipeline-${each.value.key}-${each.value.name}${local.identifiers[each.value.key]}"
  image_recipe_arn = var.recipes["${each.value.key}:${each.value.pipeline.image_recipe_arn}"].arn

  tags = try(merge({
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.pipeline"
    distroName = each.value.name
  }, var.settings[each.value.key].tags), {
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.pipeline"
    distroName = each.value.name
  })

  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.ec2ImageBuilder_pipeline_infastructure[each.value.key].arn
  distribution_configuration_arn = aws_imagebuilder_distribution_configuration.ec2ImageBuilder_pipeline_distrabution[each.value.distributionKey].arn

}
