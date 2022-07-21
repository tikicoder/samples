terraform {
  # Optional attributes and the defaults function are
  # both experimental, so we must opt in to the experiment.
  # https://github.com/hashicorp/terraform/issues/19898
  # https://www.terraform.io/docs/language/functions/defaults.html
  experiments = [module_variable_optional_attrs]
}

locals {

  identifier = length(var.global_settings.identifier) > 0 ?".${var.global_settings.identifier}" : ""

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "aws_VPC" {
  count = var.settings.skip_resource ? 0 : 1

  cidr_block = var.settings.cidr_block
  instance_tenancy = try(var.settings.instance_tenancy == "" ? null : var.settings.instance_tenancy, null)
  
  enable_dns_support =  try(var.settings.enable_dns_support == "" ? null : var.settings.enable_dns_support, null)
  enable_dns_hostnames =  try(var.settings.enable_dns_hostnames == "" ? null : var.settings.enable_dns_hostnames, null)
  enable_classiclink = try(var.settings.enable_classiclink == "" ? null : var.settings.enable_classiclink, null)
  enable_classiclink_dns_support = try(var.settings.enable_classiclink_dns_support == "" ? null : var.settings.enable_classiclink_dns_support, null)

  assign_generated_ipv6_cidr_block = try(var.settings.assign_generated_ipv6_cidr_block == "" ? null : var.settings.assign_generated_ipv6_cidr_block, null)


  tags = merge(var.global_settings.tags, try(merge({
    Name = "${var.settings.name}${local.identifier}.vpc"
  }, var.settings.tags), {
    Name = "${var.settings.name}${local.identifier}.vpc"
  }))

}

