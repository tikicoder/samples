terraform {
  backend "azurerm" { }
}

provider "azurerm" {
  environment = "public"
  version = "~> 2.2.0"
  features {}
}
