locals {  

  globalKeys = keys(var.global_settings)
  firstIndex    = try(local.globalKeys[0], "")
  environment   = try(var.global_settings[local.firstIndex].environment, "unknown")
  
}



# SM Document
locals {
  settings_ssm_document = flatten([
    for key in keys(var.settings_ssm_document) : [
      for dockey in keys(var.settings_ssm_document[key]) :{
        "key" = key
        "dockey" = dockey
        "doc" = var.settings_ssm_document[key][dockey]
      }
      if !var.settings_ssm_document[key][dockey].skip_resource 
    ]
    if contains(local.globalKeys, key) #this is to ensure nothing trys to be created that is not part of the global declaration
  ])

  settings_ssm_document_map = {
    for item in local.settings_ssm_document:
      "${item.key}_${item.dockey}" => item
  }
}

module "ssm_document_default" {
    source  = "./modules/ssm_document"
    for_each   = local.settings_ssm_document_map

    default_accountid_share = var.default_accountid_share
    
    global_settings = var.global_settings[each.value.key] 
    name                = each.value.doc.name
    version_name        = each.value.doc.version_name
    document_type       = each.value.doc.document_type
    document_format     = each.value.doc.document_format
    content             = each.value.doc.content
    permissions         = each.value.doc.permissions

}
#######################################