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

  iNetGatwayKeys = {
    for key in keys(local.keys):
      key => key
      if var.settings[key].enableInternetGatway
  }

  iNatGatwayKeys = {
    for key in keys(local.keys):
      key => key
      if var.settings[key].enableNat
  }

  subnet_keys = flatten([
    for key in keys(local.keys) : [
      for subnet in keys(var.settings[key].subnets) : {
        "key" = key
        "subnet" = subnet
      }
    ]
  ])

  subnet_keys_map = {
    for item in local.subnet_keys:
      "${item.key}:${item.subnet}" => {
        "key" = item.key
        "subnetKey" = item.subnet
        "name" = try(var.settings[item.key].subnets[item.subnet].name, item.subnet)
        "subnet" = var.settings[item.key].subnets[item.subnet]
      }
  }

  nat_keys = flatten([
    for key in keys(local.iNatGatwayKeys): [
      for natSubnet in var.settings[key].natSubnets : {
        "key" = key
        "natSubnet" = natSubnet
      }
    ]
  ])

  nat_keys_map = {
    for item in local.nat_keys:
      "${item.key}:${item.natSubnet.publicSubnet}:${item.natSubnet.privateSubnet}" => {
        "key" = item.key
        "natSubnet" = item.natSubnet
      }
  }

  public_subnet_keys = flatten([
    for key in keys(local.iNetGatwayKeys): [
      for publicSubnet in var.settings[key].publicSubnets : {
        "key" = key
        "publicSubnet" = publicSubnet
      }
    ]
  ])

  public_subnet_keys_map = {
    for item in local.public_subnet_keys:
      "${item.key}:${item.publicSubnet}" => {
        "key" = item.key
        "publicSubnet" = item.publicSubnet
      }
  }

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "ec2ImageBuilder_Subnet" {
  for_each = local.subnet_keys_map

  vpc_id     = var.settings[each.value.key].vpc_id
  cidr_block = each.value.subnet.cidr_block


  tags = try(merge({
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.subnet"
  }, var.settings[each.value.key].tags), {
    Name = "${each.value.key}.${each.value.name}${local.identifiers[each.value.key]}.subnet"
  })

}

resource "aws_route_table_association" "ec2ImageBuilder_Subnet_routeTable_Association" {
  for_each = local.subnet_keys_map

  subnet_id      = aws_subnet.ec2ImageBuilder_Subnet[each.key].id
  route_table_id = var.routeTables["${each.value.key}:${each.value.subnet.routeTable}"].id
}



# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "ec2ImageBuilder_InternetGateway" {
  for_each = local.iNetGatwayKeys

  vpc_id     = var.settings[each.key].vpc_id

  tags = try(merge({
    Name = "${each.key}.${var.settings[each.key].name}${local.identifiers[each.key]}.inetg"
  }, var.settings[each.key].tags), {
    Name = "${each.key}.${var.settings[each.key].name}${local.identifiers[each.key]}.inetg"
  })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
resource "aws_route" "InternetGatewayRoute" {
  for_each = local.public_subnet_keys_map

  route_table_id              = var.routeTables[each.key].id
  destination_cidr_block      = "0.0.0.0/0"
  gateway_id      = aws_internet_gateway.ec2ImageBuilder_InternetGateway[each.value.key].id
}

resource "aws_route" "InternetGatewayRouteIPv6" {
  for_each = local.public_subnet_keys_map

  route_table_id              = var.routeTables[each.key].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id      = aws_internet_gateway.ec2ImageBuilder_InternetGateway[each.value.key].id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
resource "aws_eip" "nat" {
  for_each = local.nat_keys_map
  
  vpc      = true

  tags = try(merge({
    Name = "${each.value.key}.${var.settings[each.value.key].name}${local.identifiers[each.value.key]}.eip"
  }, var.settings[each.value.key].tags), {
    Name = "${each.value.key}.${var.settings[each.value.key].name}${local.identifiers[each.value.key]}.eip"
  })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/nat_gateway
resource "aws_nat_gateway" "ec2ImageBuilder_NatGateway" {
  for_each = local.nat_keys_map

  allocation_id = aws_eip.nat[each.key].id
  subnet_id   = aws_subnet.ec2ImageBuilder_Subnet["${each.value.key}:${each.value.natSubnet.publicSubnet}"].id

  tags = try(merge({
    Name = "${each.value.key}.${var.settings[each.value.key].name}${local.identifiers[each.value.key]}.nat"
  }, var.settings[each.value.key].tags), {
    Name = "${each.value.key}.${var.settings[each.value.key].name}${local.identifiers[each.value.key]}.nat"
  })

  depends_on = [ aws_internet_gateway.ec2ImageBuilder_InternetGateway ]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
resource "aws_route" "NATGatewayRoute" {
  for_each = local.nat_keys_map

  nat_gateway_id              = aws_nat_gateway.ec2ImageBuilder_NatGateway[each.key].id
  route_table_id              = var.routeTables["${each.value.key}:${each.value.natSubnet.privateSubnet}"].id
  destination_cidr_block      = "0.0.0.0/0"
}

