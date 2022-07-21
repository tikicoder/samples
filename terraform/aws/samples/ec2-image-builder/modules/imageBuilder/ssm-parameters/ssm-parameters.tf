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

  ssm_param_keys = flatten([
    for key in keys(local.keys) : [
      for param in var.settings[key].ssmParams : {
        "key" = key
        "param" = param
      }
    ]
  ])

  ssm_param_map = {
    for item in local.ssm_param_keys:
      "${item.key}:${item.param.name}" => {
        "key" = item.key
        "paramKey" = item.param.name
        "name" = item.param.name
        "param"   = item.param
      }
  }


}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter
resource "aws_ssm_parameter" "ec2ImageBuilderParams" {
  for_each = local.ssm_param_map

  name  = each.value.name
  type  = each.value.param.type
  value = lower(each.value.param.type) != "securestring" ?  each.value.param.value : try(var.ssmParamters_secure[each.value.key].ssmParams[each.value.paramKey], "")

  tier = "Standard"
  overwrite = true


  tags = try(merge({
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.role"
  }, var.settings[each.value.key].tags), {
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.role"
  })
}
