# terraform plan --var-file="variable_data/network_sample.tfvars"


locals {  

  globalKeys = keys(var.global_settings)
  firstIndex    = try(local.globalKeys[0], "")
  
  
}

data "aws_region" "current" {}

###### Network #########################

module "network" {
    source  = "./modules/network"
    count   = length(keys(var.settings_network)) > 0 ? 1 : 0

    global_settings = var.global_settings  
    settings = var.settings_network  

}

#######################################

