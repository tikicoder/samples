# https://registry.terraform.io/providers/hashicorp/aws/latest/docs
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  # Optional attributes and the defaults function are
  # both experimental, so we must opt in to the experiment.
  # https://github.com/hashicorp/terraform/issues/19898
  # https://www.terraform.io/docs/language/functions/defaults.html
  experiments = [module_variable_optional_attrs]
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}