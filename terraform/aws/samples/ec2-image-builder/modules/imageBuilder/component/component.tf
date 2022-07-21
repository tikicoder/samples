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

  component_keys = flatten([
    for key in keys(local.keys) : [
      for component in keys(var.settings[key].components) : {
        "key" = key
        "component" = component
      }
    ]
  ])

  component_version_keys = flatten([
    for item in local.component_keys: [
      for version in var.settings[item.key].components[item.component].versions : {
        "key" = item.key
        "component" = item.component
        "version" = version
      }
    ]
  ])

  component_version_keys_map = {
    for item in local.component_version_keys:
      "${item.key}:${item.component}:${item.version.version}" => {
        "key"       = item.key
        "componentKey" = item.component
        "name"      = try(var.settings[item.key].components[item.component].name, item.component)
        "version"   = item.version
      }
    if try(item.version.data, "") != ""
  }

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/imagebuilder_component
resource "aws_imagebuilder_component" "ec2ImageBuilder_component" {
  for_each = local.component_version_keys_map

  name     = "Component-${each.value.name}${local.identifiers[each.value.key]}"
  platform = var.settings[each.value.key].components[each.value.componentKey].platform

  description = length(try(var.settings[each.value.key].components[each.value.componentKey].description, try(each.value.version.data.description, ""))) < 1 ? null : try(var.settings[each.value.key].components[each.value.componentKey].description, try(each.value.version.data.description, ""))
  supported_os_versions = length(try(var.settings[each.value.key].components[each.value.componentKey].supported_os_versions, [])) < 1 ? null : var.settings[each.value.key].components[each.value.componentKey].supported_os_versions

  tags = try(merge({
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.component"
  }, var.settings[each.value.key].tags), {
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.component"
  })


  version  = each.value.version.version
  data = file("${path.root}${each.value.version.data}")
  
}
