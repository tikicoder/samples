
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

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "route_table" {
  count = var.settings.skip_resource ? 0 : 1

  vpc_id = var.settings_vpc.id

  tags = merge(var.global_settings.tags, try(merge({
    Name = "${var.settings.name}${local.identifier}.vpc"
  }, var.settings.tags), {
    Name = "${var.settings.name}${local.identifier}.vpc"
  }))
  
  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      route,
    ]
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
# resource "aws_route" "r" {
#   route_table_id              = "rtb-4fbb3ac4"
#   destination_ipv6_cidr_block = "::/0"
#   egress_only_gateway_id      = aws_egress_only_internet_gateway.egress.id
# }