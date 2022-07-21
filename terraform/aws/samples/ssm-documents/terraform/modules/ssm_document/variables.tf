variable "global_settings" {
  type = object({
    identifier = string
  })
}


variable "default_accountid_share" {
  type = string
}

variable "name" {
  description = "Name to give the document"
  type        = string
}

variable "version_name" {
  description = "Version name for the document"
  type        = string
  default     = ""
}

variable "document_type" {
  description = "This can be Automation, Command, Package, Policy, and Session."
  type        = string
  validation {
    condition = contains(
      [
        "Automation", 
        "Command", 
        "Package", 
        "Policy", 
        "Session"  
      ],
      var.document_type
    )
    error_message = "This can be Automation, Command, Package, Policy, and Session."
  }
}

variable "document_format" {
  description = "This can be JSON or YAML."
  type        = string
  default     = "JSON"
  validation {
    condition = contains(
      [
        "JSON", 
        "YAML" 
      ],
      var.document_format
    )
    error_message = "This can be JSON or YAML."
  }
}

variable "content" {
  description = "The content of the doc"
  type        = string
}

variable "tags" {
  description = "tags to apply to the resource"
  type        = map(string)
  default     = {}
}

variable "permissions" {
  description = "tags to apply to the resource"
  type        = object({
      type = string
      account_ids = string
    })
  default     = {
      type = "share"
      account_ids = ""
    }
}