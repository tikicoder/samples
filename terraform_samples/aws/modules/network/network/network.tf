terraform {
  # Optional attributes and the defaults function are
  # both experimental, so we must opt in to the experiment.
  # https://github.com/hashicorp/terraform/issues/19898
  # https://www.terraform.io/docs/language/functions/defaults.html
  experiments = [module_variable_optional_attrs]
}

locals {

  identifier = length(var.global_settings.identifier) > 0 ?".${var.global_settings.identifier}" : ""

  subnets = {
    for key in keys(var.settings.subnets) :
    key => var.settings.subnets[key]
    if !var.settings.subnets[key].skip_resource #this is to ensure nothing trys to be created that is not part of the global declaration
  }

  public_subnets = {
    for key in keys(var.settings.subnets) :
    key => var.settings.subnets[key]
    if contains(var.settings.public_subnets, key) #this is to ensure nothing trys to be created that is not part of the global declaration
  }

  nat_subnets = {
    for item in var.settings.nat_subnets :
    "${item.public}:${item.private}" => item
  }

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "subnet" {  
  for_each = local.subnets

  vpc_id = var.settings_vpc.id
  cidr_block = each.value.cidr_block


  tags = merge(var.global_settings.tags, try(merge({
    Name = "${each.value.name}${local.identifier}.subnet"
  }, var.settings.tags), {
    Name = "${each.value.name}${local.identifier}.subnet"
  }))

}

resource "aws_route_table_association" "subnet_routeTable_association" {
  for_each = local.subnets

  subnet_id      = aws_subnet.subnet[each.key].id
  route_table_id = var.route_table[each.value.route_table]
}



# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "internet_gateway" {
  for_each = local.public_subnets

  vpc_id     = var.settings_vpc.id

  tags = merge(var.global_settings.tags, try(merge({
    Name = "${each.value.name}${local.identifier}.inetg"
  }, var.settings.tags), {
    Name = "${each.value.name}${local.identifier}.inetg"
  }))
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
resource "aws_route" "internet_gateway_route" {
  for_each = local.public_subnets

  route_table_id              =  var.route_table[each.value.route_table]
  destination_cidr_block      = "0.0.0.0/0"
  gateway_id      = aws_internet_gateway.internet_gateway[each.key].id
}

resource "aws_route" "InternetGatewayRouteIPv6" {
  for_each = local.public_subnets

  route_table_id              =  var.route_table[each.value.route_table]
  destination_ipv6_cidr_block = "::/0"
  gateway_id      = aws_internet_gateway.internet_gateway[each.key].id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
resource "aws_eip" "eip" {
  for_each = local.nat_subnets
  
  vpc      = true

  tags = merge(var.global_settings.tags, try(merge({
    Name = "${local.subnets[each.value.public].name}${local.identifier}.eip"
  }, var.settings.tags), {
    Name = "${local.subnets[each.value.public].name}${local.identifier}.eip"
  }))
}

# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/nat_gateway
resource "aws_nat_gateway" "nat_gateway" {
  for_each = local.nat_subnets

  allocation_id = aws_eip.eip[each.key].id
  subnet_id   = aws_subnet.subnet[each.value.public].id

  tags = merge(var.global_settings.tags, try(merge({
    Name = "${local.subnets[each.value.public].name}${local.identifier}.nat"
  }, var.settings.tags), {
    Name = "${local.subnets[each.value.public].name}${local.identifier}.nat"
  }))

  depends_on = [ aws_internet_gateway.internet_gateway ]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
resource "aws_route" "nat_gateway_route" {
  for_each = local.nat_subnets

  nat_gateway_id              = aws_nat_gateway.nat_gateway[each.key].id
  route_table_id              = var.route_table[local.subnets[each.value.private].route_table]
  destination_cidr_block      = "0.0.0.0/0"
}

