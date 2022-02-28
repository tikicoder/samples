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

  recipe_keys = flatten([
    for key in keys(local.keys) : [
      for recipe in keys(var.settings[key].recipes) : {
        "key" = key
        "recipe" = recipe
      }
    ]
  ])

  recipe_version_keys = flatten([
    for item in local.recipe_keys: [
      for version in var.settings[item.key].recipes[item.recipe].versions : {
        "key" = item.key
        "recipe" = item.recipe
        "version" = version
      }
    ]
  ])

  recipe_version_keys_map = {
    for item in local.recipe_version_keys:
      "${item.key}:${item.recipe}:${item.version.version}" => {
        "key"       = item.key
        "recipeKey" = item.recipe
        "name"      = try(var.settings[item.key].recipes[item.recipe].name, item.recipe)
        "version"   = item.version
      }
  }

  

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/imagebuilder_image_recipe
resource "aws_imagebuilder_image_recipe" "ec2ImageBuilder_recipe" {
  for_each = local.recipe_version_keys_map

  name     = "Recipe-${each.value.key}-${each.value.name}${local.identifiers[each.value.key]}"
  parent_image = var.settings[each.value.key].recipes[each.value.recipeKey].parent_image

  tags = try(merge({
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.recipe"
  }, var.settings[each.value.key].tags), {
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.recipe"
  })


  version  = each.value.version.version

  dynamic "block_device_mapping" {
    for_each = each.value.version.ebs

    content {
      device_name = block_device_mapping.value["device_name"]

      ebs {
        delete_on_termination = block_device_mapping.value.ebs_delete_on_termination
        encrypted             = true
        volume_size           = block_device_mapping.value.ebs_volume_size
        volume_type           = block_device_mapping.value.ebs_volume_type
      }
    }
  }
  
  dynamic "component" {
    for_each = each.value.version.components

    content {
      component_arn = substr(component.value, 0, 4) == "arn:" ? component.value : (substr(component.value, 0, length(each.value.key)+1) == "${each.value.key}:" ? var.component_arn[component.value] : var.component_bygeneralkey["${each.value.key}:${component.value}"])
    }
  }
  
}
