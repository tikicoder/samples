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

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint
resource "aws_vpc_endpoint" "endpoint" {
  count = var.settings.skip_resource ? 0 : 1

  vpc_id = var.settings_vpc.id
  service_name      = var.settings.service_name
  vpc_endpoint_type = var.settings.vpc_endpoint_type

  tags = try(merge({
    Name = replace("${var.settings.name}${local.identifier}.endpoint", "%vpc_name%", var.settings_vpc.vpc_name)
  }, var.settings.tags), {
    Name = replace("${var.settings.name}${local.identifier}.endpoint", "%vpc_name%", var.settings_vpc.vpc_name)
  })

  security_group_ids = lower(var.settings.vpc_endpoint_type) == "interface" ? var.security_group_ids : null
  subnet_ids = lower(var.settings.vpc_endpoint_type) == "interface" ? var.subnet_ids : null

  private_dns_enabled = lower(var.settings.vpc_endpoint_type) == "interface" ? var.settings.private_dns_enabled : null

  route_table_ids = lower(var.settings.vpc_endpoint_type) == "gateway" ? var.route_table_ids : null
}

