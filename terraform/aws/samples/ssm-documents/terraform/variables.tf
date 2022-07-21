variable "region" {
  type = string
  default = "us-east-1"
}

variable "default_accountid_share" {
  type = string
  default = ""
}

variable "global_settings" {
  type = map(object({
    identifier = string
  }))
}

variable "settings_ssm_document" {
  type = map(object({
    skip_resource = bool
    tags = map(any)
    
    name = string
    version_name = string
    
    document_type = string
    document_format = string

    content = string

    permissions = object({
      type = string
      account_ids = string
    })

  }))
}