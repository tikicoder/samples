locals {
  keys = {
    for key in keys(var.settings):
      key => key
      if contains(keys(var.global_settings), key) && !var.settings[key].skip_resource
  }

  identifiers = {
    for key in local.keys:
      key => length(var.global_settings[key].identifier) > 0 ?".${var.global_settings[key].identifier}" : ""
  }

  securitygroup_keys = flatten([
    for key in keys(local.keys) : [
      for securityGroup in keys(var.settings[key].securityGroups) : {
        "key" = key
        "securityGroup" = securityGroup
      }
    ]
  ])

  securitygroup_keys_map = {
    for item in local.securitygroup_keys:
      "${item.key}:${item.securityGroup}" => {
        "key" = item.key
        "securityGroupKey" = item.securityGroup
        "name" = replace(try(var.settings[item.key].securityGroups[item.securityGroup].name, item.securityGroup), "%vpc_name%", var.settings[item.key].vpc_name)
        "securityGroup" = var.settings[item.key].securityGroups[item.securityGroup]
      }
  }
  

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "ec2ImageBuilder_SecurityGroups" {
  for_each = local.securitygroup_keys_map

  name        = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.sg"
  description = each.value.securityGroup.description
  vpc_id = var.settings[each.value.key].vpc_id

  tags = try(merge({
    Name = replace("${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.sg", "%vpc_name%", var.settings[each.value.key].vpc_name)
  }, var.settings[each.value.key].tags), {
    Name = replace("${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.sg", "%vpc_name%", var.settings[each.value.key].vpc_name)
  })

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      ingress,
      egress
    ]
  }
}

# add default rule of sg-05887620abf132531 / nonprod.terraformTestRon.sg

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "ec2ImageBuilder_SecurityGroup_Rules_Ingress" {
  for_each = local.securitygroup_keys_map

  type              = "ingress"
  protocol          = "all"
  from_port         = 0
  to_port           = 0
  security_group_id = aws_security_group.ec2ImageBuilder_SecurityGroups[each.key].id
  source_security_group_id = aws_security_group.ec2ImageBuilder_SecurityGroups[each.key].id
  
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "ec2ImageBuilder_SecurityGroup_Rules_Egress" {
  for_each = local.securitygroup_keys_map

  type              = "egress"
  protocol          = "all"
  from_port         = 0
  to_port           = 0
  security_group_id = aws_security_group.ec2ImageBuilder_SecurityGroups[each.key].id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}
