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

  routetable_keys = flatten([
    for key in keys(local.keys) : [
      for routesTable in keys(var.settings[key].routesTables) : {
        "key" = key
        "routesTable" = routesTable
      }
    ]
  ])

  routetable_keys_map = {
    for item in local.routetable_keys:
      "${item.key}:${item.routesTable}" => {
        "key" = item.key
        "routeTableKey" = item.routesTable
        "name" = try(var.settings[item.key].routesTables[item.routesTable].name, item.routesTable)
        "routesTable" = var.settings[item.key].routesTables[item.routesTable]
      }
  }
  

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "ec2ImageBuilder_RouteTables" {
  for_each = local.routetable_keys_map

  vpc_id = var.settings[each.value.key].vpc_id

  tags = try(merge({
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.routetable"
  }, var.settings[each.value.key].tags), {
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.routetable"
  })

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