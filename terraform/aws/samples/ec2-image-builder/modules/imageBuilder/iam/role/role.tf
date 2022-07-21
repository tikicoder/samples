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

  role_keys = flatten([
    for key in keys(local.keys) : [
      for role in keys(var.settings[key].roles) : {
        "key" = key
        "role" = role
      }
    ]
  ])

  role_keys_map = {
    for item in local.role_keys:
      "${item.key}:${item.role}" => {
        "key" = item.key
        "roleKey" = item.role
        "name" = try(var.settings[item.key].roles[item.role].name, item.role)
        "role"   = var.settings[item.key].roles[item.role]
      }
  }

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/imagebuilder_component
resource "aws_iam_role" "ec2ImageBuilder_iam_role" {
  for_each = local.role_keys_map

  name     = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.role"

  tags = try(merge({
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.role"
  }, var.settings[each.value.key].tags), {
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.role"
  })

  managed_policy_arns = length(try(each.value.role.managed_policy_arns, []))<1?null:each.value.role.managed_policy_arns  
  assume_role_policy = jsonencode(each.value.role.assume_role_policy)
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile
resource "aws_iam_instance_profile" "ec2ImageBuilder_pipeline_infastructure_iamInstanceProfile" {
  for_each = local.role_keys_map

  name = aws_iam_role.ec2ImageBuilder_iam_role[each.key].name
  role = aws_iam_role.ec2ImageBuilder_iam_role[each.key].name
}