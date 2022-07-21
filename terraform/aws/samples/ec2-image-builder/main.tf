# terraform plan --var-file="variable_data/ec2ImageBuilder.tfvars"
locals {  

  globalKeys = keys(var.global_settings)
  firstIndex    = try(local.globalKeys[0], "")
  environment   = try(var.global_settings[local.firstIndex].environment, "unknown")
  
}

data "aws_region" "current" {}

# VPC
locals {
  settings_vpc = {
    for key in keys(var.settings_vpc) :
    key => var.settings_vpc[key]
    if contains(local.globalKeys, key) && !var.settings_vpc[key].skip_resource #this is to ensure nothing trys to be created that is not part of the global declaration
  }
}

module "vpc" {
    source  = "./modules/network/vpc"
    count   = length(keys(local.settings_vpc)) > 0 ? 1 : 0

    global_settings = var.global_settings  
    settings        = local.settings_vpc
}
#######################################


#Route Tables
locals {
  settings_routetable = {
    for key in keys(var.settings_routetable) :
    key => merge(var.settings_routetable[key], {
      vpc_id = try(module.vpc[0].vpc[key].id, "")
    })
    if contains(local.globalKeys, key) && !var.settings_routetable[key].skip_resource
  }
}

module "route_table" {
    source  = "./modules/network/route_table"
    count   = length(keys(local.settings_routetable)) > 0 ? 1 : 0

    global_settings = var.global_settings  
    settings        = local.settings_routetable

    depends_on = [
      module.vpc
    ]
}
#######################################

# Security Groups
locals {
  settings_securitygroup = {
    for key in keys(var.settings_securitygroup) :
    key => merge(var.settings_securitygroup[key], {
      vpc_id = try(module.vpc[0].vpc[key].id, "")
      vpc_name = try(var.settings_vpc[key].name, "")
    })
    if contains(local.globalKeys, key) && !var.settings_securitygroup[key].skip_resource
  }
}

module "security_group" {
    source  = "./modules/network/security_group"
    count   = length(keys(local.settings_securitygroup)) > 0 ? 1 : 0

    global_settings = var.global_settings  
    settings        = local.settings_securitygroup

    depends_on = [
      module.vpc
    ]
}
#######################################

# Network
locals {
  settings_network = {
    for key in keys(var.settings_network) :
    key => merge(var.settings_network[key], {
      vpc_id = try(module.vpc[0].vpc[key].id, "")
      name = var.settings_vpc[key].name
      enableInternetGatway = try(length(var.settings_network[key].publicSubnets)>0, false)
      enableNat = try(length(var.settings_network[key].natSubnets)>0, false)

    })
    if contains(local.globalKeys, key) && !var.settings_network[key].skip_resource
  }
}

module "network" {
    source  = "./modules/network/network"
    count   = length(keys(local.settings_network)) > 0 ? 1 : 0

    global_settings = var.global_settings  
    settings        = local.settings_network

    routeTables = try(module.route_table[0].routeTables, {})

    depends_on = [
      module.route_table
    ]
}
#######################################


# SSM Params Needed by EC2 Image Builder/Components
locals {
  settings_ssmParamters = {
    for key in keys(var.settings_ssmParamters) :
    key => var.settings_ssmParamters[key]
    if contains(local.globalKeys, key) && !var.settings_ssmParamters[key].skip_resource
  }
}

module "ec2ImageBuilder_ssm_Params" {
    source  = "./modules/imageBuilder/ssm-parameters"
    count   = length(keys(local.settings_ssmParamters)) > 0 ? 1 : 0

    global_settings = var.global_settings  
    settings        = local.settings_ssmParamters
    ssmParamters_secure = var.settings_ssmParamters_secure
}
#######################################


# EC2 Image Builder Network Endpoint
locals {
  settings_ec2ImageBuilder_network_endPoint = {
    for key in keys(var.settings_ec2ImageBuilder_network_endPoint) :
    key => merge(var.settings_ec2ImageBuilder_network_endPoint[key], {
      vpc_id = try(module.vpc[0].vpc[key].id, "")
      vpc_name = try(var.settings_vpc[key].name, "")

    })
    if contains(local.globalKeys, key) && !var.settings_ec2ImageBuilder_network_endPoint[key].skip_resource
  }
}

module "ec2ImageBuilder_network_endPoint" {
    source  = "./modules/imageBuilder/network/end_point"
    count   = length(keys(local.settings_ec2ImageBuilder_network_endPoint)) > 0 ? 1 : 0

    global_settings = var.global_settings  
    settings        = local.settings_ec2ImageBuilder_network_endPoint

    routeTables = try(module.route_table[0].routeTables, {})
    securityGroups = try(module.security_group[0].securityGroups, {})
    subnets = try(module.network[0].subnets, {})

    depends_on = [
      module.route_table, 
      module.security_group, 
      module.network, 
    ]
}
#######################################


# EC2 Image Builder IAM Role
locals {
  settings_ec2ImageBuilder_iam_role = {
    for key in keys(var.settings_ec2ImageBuilder_iam_role) :
    key => var.settings_ec2ImageBuilder_iam_role[key]
    if contains(local.globalKeys, key) && !var.settings_ec2ImageBuilder_iam_role[key].skip_resource
  }
}

module "ec2ImageBuilder_iam_role" {
    source  = "./modules/imageBuilder/iam/role"
    count   = length(keys(local.settings_ec2ImageBuilder_iam_role)) > 0 ? 1 : 0

    global_settings = var.global_settings  
    settings        = local.settings_ec2ImageBuilder_iam_role
}
#######################################


# EC2 Image Builder Components
locals {
  settings_ec2ImageBuilder_component = {
    for key in keys(var.settings_ec2ImageBuilder_component) :
    key => var.settings_ec2ImageBuilder_component[key]
    if contains(local.globalKeys, key) && !var.settings_ec2ImageBuilder_component[key].skip_resource
  }
}

module "ec2ImageBuilder_component" {
    source  = "./modules/imageBuilder/component"
    count   = length(keys(local.settings_ec2ImageBuilder_component)) > 0 ? 1 : 0

    global_settings = var.global_settings  
    settings        = local.settings_ec2ImageBuilder_component
}
#######################################


# EC2 Image Builder Recipe
locals {
  settings_ec2ImageBuilder_recipe = {
    for key in keys(var.settings_ec2ImageBuilder_recipe) :
    key => var.settings_ec2ImageBuilder_recipe[key]
    if contains(local.globalKeys, key) && !var.settings_ec2ImageBuilder_recipe[key].skip_resource
  }
}

module "ec2ImageBuilder_recipe" {
    source  = "./modules/imageBuilder/recipe"
    count   = length(keys(local.settings_ec2ImageBuilder_recipe)) > 0 ? 1 : 0

    global_settings = var.global_settings  
    settings        = local.settings_ec2ImageBuilder_recipe

    component_arn = module.ec2ImageBuilder_component[0].component_arn
    component_bygeneralkey = module.ec2ImageBuilder_component[0].component_bygeneralkey

    depends_on = [
      module.ec2ImageBuilder_component, 
    ]
}
#######################################



# EC2 Image Builder Pipeline
locals {
  settings_ec2ImageBuilder_pipeline = {
    for key in keys(var.settings_ec2ImageBuilder_pipeline) :
    key => var.settings_ec2ImageBuilder_pipeline[key]
    if contains(local.globalKeys, key) && !var.settings_ec2ImageBuilder_pipeline[key].skip_resource
  }
}

module "ec2ImageBuilder_pipeline" {
    source  = "./modules/imageBuilder/pipeline"
    count   = length(keys(local.settings_ec2ImageBuilder_pipeline)) > 0 ? 1 : 0

    global_settings = var.global_settings  
    settings        = local.settings_ec2ImageBuilder_pipeline

    recipes = module.ec2ImageBuilder_recipe[0].recipes
    securityGroups = try(module.security_group[0].securityGroups, {})
    subnets = try(module.network[0].subnets, {})
    iamRoles = module.ec2ImageBuilder_iam_role[0].role_profiles

    depends_on = [
      module.ec2ImageBuilder_recipe, 
      module.security_group, 
      module.network, 
    ]
}
#######################################