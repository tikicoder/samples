

resource "aws_ssm_document" "ssm_document" {
  name              = var.name
  version_name      = var.version_name
  document_type     = var.document_type
  document_format   = var.document_format

  content           = file("${path.root}${var.content}")

  permissions = try(var.permissions.account_ids.length, 0) < 1 ? merge(var.permissions, {account_ids= var.default_accountid_share }) : var.permissions

  tags              = var.tags
}

