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

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "ec2ImageBuilder_VPC" {
  for_each = local.keys

  cidr_block = var.settings[each.key].cidr_block
  instance_tenancy = try(var.settings[each.key].instance_tenancy == "" ? "default" : var.settings[each.key].instance_tenancy, "default")
  
  enable_dns_support =  try(var.settings[each.key].enable_dns_support, true)
  enable_dns_hostnames =  try(var.settings[each.key].enable_dns_hostnames, false)
  enable_classiclink = try(var.settings[each.key].enable_classiclink, false)
  enable_classiclink_dns_support = try(var.settings[each.key].enable_classiclink_dns_support, false)

  assign_generated_ipv6_cidr_block = try(var.settings[each.key].assign_generated_ipv6_cidr_block, false)


  tags = try(merge({
    Name = "${each.key}.${var.settings[each.key].name}${local.identifiers[each.key]}.vpc"
  }, var.settings[each.key].tags), {
    Name = "${each.key}.${var.settings[each.key].name}${local.identifiers[each.key]}.vpc"
  })

}

