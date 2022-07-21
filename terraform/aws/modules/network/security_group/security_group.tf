terraform {
  # Optional attributes and the defaults function are
  # both experimental, so we must opt in to the experiment.
  # https://github.com/hashicorp/terraform/issues/19898
  # https://www.terraform.io/docs/language/functions/defaults.html
  experiments = [module_variable_optional_attrs]
}

locals {

  identifier = length(var.global_settings.identifier) > 0 ?".${var.global_settings.identifier}" : ""

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "security_group" {
  count = var.settings.skip_resource ? 0 : 1

  name  =  replace("${var.settings.name}${local.identifier}.sg", "%vpc_name%", var.settings_vpc.vpc_name)
  
  vpc_id = var.settings_vpc.id
  tags = merge(var.global_settings.tags, try(merge({
    Name = "${var.settings.name}${local.identifier}.sg"
  }, var.settings.tags), {
    Name = "${var.settings.name}${local.identifier}.sg"
  }))
  description = try(var.settings.description, null)


  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      ingress,
      egress
    ]
  }
}

# add default rules
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "ec2ImageBuilder_SecurityGroup_Rules_Ingress" {
  count = var.settings.skip_resource ? 0 : 1

  type              = "ingress"
  protocol          = "all"
  from_port         = 0
  to_port           = 0
  security_group_id = aws_security_group.security_group[0].id
  source_security_group_id = aws_security_group.security_group[0].id
  
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "ec2ImageBuilder_SecurityGroup_Rules_Egress" {
  count = var.settings.skip_resource ? 0 : 1


  type              = "egress"
  protocol          = "all"
  from_port         = 0
  to_port           = 0
  security_group_id = aws_security_group.security_group[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

