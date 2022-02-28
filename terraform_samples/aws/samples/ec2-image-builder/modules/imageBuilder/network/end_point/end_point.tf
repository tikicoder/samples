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

  interface_keys = flatten([
    for key in keys(local.keys) : [
      for interface in keys(var.settings[key].interfaceEndpoints) : {
        "key" = key
        "interface" = interface
      }
    ]
  ])

  interface_keys_map = {
    for item in local.interface_keys:
      "${item.key}:${item.interface}" => {
        "key" = item.key
        "interfaceKey"  = item.interface
        "name"          = replace(try(var.settings[item.key].interfaceEndpoints[item.interface].name, item.interface), "%vpc_name%", var.settings[item.key].vpc_name)
        "interface"     = var.settings[item.key].interfaceEndpoints[item.interface]
      }
  }

  interface_securitygroup_map = {
    for key in keys(local.interface_keys_map): 
      key => flatten([
        for securityGroupID in local.interface_keys_map[key].interface.security_group_ids: [
          try(var.securityGroups["${local.interface_keys_map[key].key}:${securityGroupID}"].id, "")
        ]
        if try(var.securityGroups["${local.interface_keys_map[key].key}:${securityGroupID}"].id, "") != ""
      ])
  }

  interface_subnet_map = {
    for key in keys(local.interface_keys_map): 
      key => flatten([
        for subnetID in local.interface_keys_map[key].interface.subnet_ids: [
          try(var.subnets["${local.interface_keys_map[key].key}:${subnetID}"].id, "")
        ]
        if try(var.subnets["${local.interface_keys_map[key].key}:${subnetID}"].id, "") != ""
      ])
  }

  gateway_keys = flatten([
    for key in keys(local.keys) : [
      for gateway in keys(var.settings[key].gatewayEndpoints) : {
        "key" = key
        "gateway" = gateway
      }
    ]
  ])

  gateway_keys_map = {
    for item in local.gateway_keys:
      "${item.key}:${item.gateway}" => {
        "key"         = item.key
        "gatewayKey"  = item.gateway
        "name"        = replace(try(var.settings[item.key].gatewayEndpoints[item.gateway].name, item.gateway), "%vpc_name%", var.settings[item.key].vpc_name)
        "gateway"     = var.settings[item.key].gatewayEndpoints[item.gateway]
      }
  }

  gateway_routetable_map = {
    for key in keys(local.gateway_keys_map): 
      key => flatten([
        for routeTableID in local.gateway_keys_map[key].gateway.route_table_ids: [
          try(var.routeTables["${local.gateway_keys_map[key].key}:${routeTableID}"].id, "")
        ]
        if try(var.routeTables["${local.gateway_keys_map[key].key}:${routeTableID}"].id, "") != ""
      ])
  }

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint
resource "aws_vpc_endpoint" "ec2ImageBuilder_VPC_EndPoint_Interface" {
  for_each = local.interface_keys_map

  vpc_id = var.settings[each.value.key].vpc_id
  service_name      = each.value.interface.service_name
  vpc_endpoint_type = "Interface"

  tags = try(merge({
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.endpoint"
  }, var.settings[each.value.key].tags), {
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.endpoint"
  })

  security_group_ids = length(try(local.interface_securitygroup_map[each.key], [])) < 1 ? null : local.interface_securitygroup_map[each.key]
  subnet_ids = length(try(local.interface_subnet_map[each.key], [])) < 1 ? null : local.interface_subnet_map[each.key]

  private_dns_enabled = each.value.interface.private_dns_enabled
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint
resource "aws_vpc_endpoint" "ec2ImageBuilder_VPC_EndPoint_Gateway" {
  for_each = local.gateway_keys_map

  vpc_id = var.settings[each.value.key].vpc_id
  service_name      = each.value.gateway.service_name
  vpc_endpoint_type = "Gateway"

  tags = try(merge({
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.endpoint"
  }, var.settings[each.value.key].tags), {
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.endpoint"
  })

  route_table_ids = length(try(local.gateway_routetable_map[each.key], [])) < 1 ? null : local.gateway_routetable_map[each.key]

}

