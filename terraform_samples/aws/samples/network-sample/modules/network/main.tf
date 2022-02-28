terraform {
  # Optional attributes and the defaults function are
  # both experimental, so we must opt in to the experiment.
  # https://github.com/hashicorp/terraform/issues/19898
  # https://www.terraform.io/docs/language/functions/defaults.html
  experiments = [module_variable_optional_attrs]
}


locals {  

  globalKeys = keys(var.global_settings)
  firstIndex    = try(local.globalKeys[0], "")
  
}



###### VPC #########################
locals {
  vpc_default = { skip_resource = true, name = "", cidr_block = "" }
  network_vpcs = flatten([
    for key in keys(var.settings) : [
      for item_key in keys(var.settings[key].vpc) : {
        "key" = key
        "item_key" = item_key
        "item" = var.settings[key].vpc[item_key]
      }
    ]
  ])

  network_vpcs_map = {
    for item in local.network_vpcs:
      "${item.key}:${item.item_key}" => item
  }
}

module "vpc" {
    source  = "../../../../modules/network/vpc"
    for_each = local.network_vpcs_map

    global_settings = var.global_settings[each.value.key]
    settings = try(each.value.item, local.vpc_default)

}

#######################################


###### Route Tables #########################
locals {
  route_table_default = { skip_resource = true, name = "", vpc_id = ""}
  network_route_tables = flatten([
    for key in keys(var.settings) : [
      for item_key in keys(var.settings[key].route_table) : {
        "key" = key
        "item_key" = item_key
        "item" = var.settings[key].route_table[item_key]
      }
    ]
  ])

  network_route_tables_map = {
    for item in local.network_route_tables:
      "${item.key}:${item.item.vpc_id}:${item.item_key}" => item
  }
}

module "route_table" {
    source  = "../../../../modules/network/route_table"
    for_each = local.network_route_tables_map

    global_settings = var.global_settings[each.value.key]
    settings = try(each.value.item, local.route_table_default)
    settings_vpc = { id = module.vpc["${each.value.key}:${each.value.item.vpc_id}"].vpc.id, vpc_name = local.network_vpcs_map["${each.value.key}:${each.value.item.vpc_id}"].item.name }

    depends_on = [
      module.vpc
    ]
}
#######################################


###### Security Groups #########################
locals {
  security_group_default = { skip_resource = true, name = "", vpc_id = "", description = ""}
  network_security_group = flatten([
    for key in keys(var.settings) : [
      for item_key in keys(var.settings[key].security_group) : {
        "key" = key
        "item_key" = item_key        
        "item" = var.settings[key].security_group[item_key]
      }
    ]
  ])

  network_security_group_map = {
    for item in local.network_security_group:
      "${item.key}:${item.item_key}" => item
  }
}

module "security_group" {
    source  = "../../../../modules/network/security_group"
    for_each = local.network_security_group_map

    global_settings = var.global_settings[each.value.key]
    settings = try(each.value.item, local.security_group_default)
    settings_vpc = { id = module.vpc["${each.value.key}:${each.value.item.vpc_id}"].vpc.id, vpc_name = local.network_vpcs_map["${each.value.key}:${each.value.item.vpc_id}"].item.name }

    depends_on = [
      module.vpc
    ]
}
#######################################


###### Network #########################
locals {
  network_default = { skip_resource = true, name = "", vpc_id = "", subnets = {cidr_block="", route_table=""}}
  network_network = flatten([
    for key in keys(var.settings) : [
      for item_key in keys(var.settings[key].network) : {
        "key" = key
        "item_key" = item_key
        "item" = var.settings[key].network[item_key]
      }
    ]
  ])

  network_network_map = {
    for item in local.network_network:
      "${item.key}:${item.item_key}" => item
  }

  

  route_table_group_by_vpc = {
    for item in local.network_network_map: 
      "${item.key}:${item.item.vpc_id}" => {
        for key in keys(module.route_table) : 
          substr(key,  length("${item.key}:${item.item.vpc_id}")+1, length(key)-(length("${item.key}:${item.item.vpc_id}")+1)) => module.route_table[key].route_table.id       
        if substr(key, 0, length("${item.key}:${item.item.vpc_id}" )) == "${item.key}:${item.item.vpc_id}" 
      }
  }
}

module "network" {
    source  = "../../../../modules/network/network"
    for_each = local.network_network_map

    global_settings = var.global_settings[each.value.key]
    settings = try(each.value.item, local.network_default)
    settings_vpc = { id = module.vpc["${each.value.key}:${each.value.item.vpc_id}"].vpc.id, vpc_name = local.network_vpcs_map["${each.value.key}:${each.value.item.vpc_id}"].item.name }
    route_table =  local.route_table_group_by_vpc["${each.value.key}:${each.value.item.vpc_id}"]

    depends_on = [
      module.vpc,
      module.route_table
    ]
}
#######################################


###### Endpoints #########################
locals {
  endpoint_default = { skip_resource = true, service_name = "", name = "", vpc_endpoint_type = ""}
  network_endpoint = flatten([
    for key in keys(var.settings) : [
      for item_key in keys(var.settings[key].endpoint) : {
        "key" = key
        "item_key" = item_key
      }
    ]
  ]) 

  network_endpoint_endpoint = flatten([
    for item in local.network_endpoint: [
      for endpoint_key in keys(var.settings[item.key].endpoint[item.item_key].endpoint) : {
        "key"       = item.key
        "item_key" = item.item_key
        "item" = var.settings[item.key].endpoint[item.item_key]
        "endpoint_key" = endpoint_key
        "endpoint" = var.settings[item.key].endpoint[item.item_key].endpoint[endpoint_key]
      }
    ]
  ])

  network_endpoint_endpoint_map = {
    for item in local.network_endpoint_endpoint:
      "${item.key}:${item.item_key}:${item.endpoint_key}" => item
  }

  security_group_by_endpoint = {
    for key in keys(local.network_endpoint_endpoint_map): 
      key => compact(distinct(flatten([
        for group in (try(local.network_endpoint_endpoint_map[key].endpoint.security_group_ids, []) == null ? [] : try(local.network_endpoint_endpoint_map[key].endpoint.security_group_ids, [])): 
          module.security_group["${local.network_endpoint_endpoint_map[key].key}:${group}"].security_group.id
        if try(module.security_group["${local.network_endpoint_endpoint_map[key].key}:${group}"], null) != null

      ])))
  }

  subnet_by_endpoint = {
    for key in keys(local.network_endpoint_endpoint_map): 
      key => compact(distinct(flatten([
        for subnet in (try(local.network_endpoint_endpoint_map[key].endpoint.subnet_ids, []) == null ? [] : try(local.network_endpoint_endpoint_map[key].endpoint.subnet_ids, [])): 
          module.network["${local.network_endpoint_endpoint_map[key].key}:${local.network_endpoint_endpoint_map[key].item.network}"].subnet[subnet].id
        if try(module.network["${local.network_endpoint_endpoint_map[key].key}:${local.network_endpoint_endpoint_map[key].item.network}"].subnet[subnet], null) != null

      ])))
  }

  route_table_by_endpoint = {
    for key in keys(local.network_endpoint_endpoint_map): 
      key => compact(distinct(flatten([
        for route_table in (try(local.network_endpoint_endpoint_map[key].endpoint.route_table_ids, []) == null ? [] : try(local.network_endpoint_endpoint_map[key].endpoint.route_table_ids, [])): 
          module.route_table["${local.network_endpoint_endpoint_map[key].key}:${local.network_endpoint_endpoint_map[key].item.vpc_id}"][route_table].id
        if try(module.route_table["${local.network_endpoint_endpoint_map[key].key}:${local.network_endpoint_endpoint_map[key].item.vpc_id}"][route_table], null) != null

      ])))
  }
  
}

module "endpoint" {
    source  = "../../../../modules/network/endpoint"
    for_each = local.network_endpoint_endpoint_map

    global_settings = var.global_settings[each.value.key]
    settings = try(merge(each.value.endpoint, {skip_resource = each.value.item.skip_resource, tags = each.value.item.tags}), local.endpoint_default)
    settings_vpc = { id = module.vpc["${each.value.key}:${each.value.item.vpc_id}"].vpc.id, vpc_name = local.network_vpcs_map["${each.value.key}:${each.value.item.vpc_id}"].item.name }
    security_group_ids =  length(try(local.security_group_by_endpoint[each.key], [])) < 1 ? null : local.security_group_by_endpoint[each.key]
    subnet_ids =  length(try(local.subnet_by_endpoint[each.key], [])) < 1 ? null : local.subnet_by_endpoint[each.key]
    route_table_ids =  length(try(local.route_table_by_endpoint[each.key], [])) < 1 ? null : local.route_table_by_endpoint[each.key]

    depends_on = [
      module.vpc,
      module.route_table,
      module.security_group,
      module.network
    ]
}
#######################################