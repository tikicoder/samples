# terraform init
# terraform plan --var-file="data.tfvars"
locals {  

  identifier = {
    for key in keys( var.global_settings) :
    key => "${var.global_settings[key].identifier}-hello"
  }
  
}



# Sample
module "sample1" {
    source  = "./sample-module"
    for_each = local.identifier

    identifier = "${each.key}-${each.value}"
}
#######################################

# Sample
module "sample2" {
    source  = "./sample-module"
    count   = length(keys(local.identifier)) > 0 ? 1 : 0

    identifier = "hello${count.index}"
}
#######################################

# Sample
module "sample3" {
    source  = "./sample-module"
    count   = length(keys(local.identifier))

    identifier = "hello${count.index}"
}
#######################################

