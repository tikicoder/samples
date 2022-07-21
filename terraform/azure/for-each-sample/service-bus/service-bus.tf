locals {
  keys = {
    for item in keys(var.settings):
      "_${item}" => item
  }
  integration_topics = [    
    "sws-product-v2-v3",
    "sws-familyregisteredcard-v2-v3",
    "sws-familyregisteredcard-v3-v2",
    "sws-familyaccount-v2-v3",
    "sws-familyaccount-v3-v2",
    "sws-familychallengequestion-v2-v3",
    "sws-familyenrollment-v2-v3",
    "sws-familyenrollment-v3-v2",
    "sws-identityusers-v2-v3",
    "sws-identityusers-v3-v2",
    "sws-organization-v2-v3",
    "sws-securityquestionanswers-v3-v2",
    "sws-twofactorphone-v2-v3",
    "sws-twofactorphone-v3-v2",
    "sws-productprice-v2-v3",
    "sws-scheduled-effective-productprices-v2-v3",
    "sws-scheduled-terminated-productprices-v2-v3",
    "sws-validreloadnumbers-v2-v3",
    "sws-brand-v2-v3",
    "sws-barcodeviewcontrols-v2-v3",  
    "sws-family-enrollment-completed-v2-v3",
    "sws-vcerttransaction-v2-v3",
    "sws-organization-payment-type-configuration-v2-v3",
    "sws-family-payment-type-configuration-v2-v3",
    "sws-accountlink-v2-v3",
    "sws-vcerttransaction-v3-v2",
    "sws-accountlink-v3-v2"
  ]
  resource_group_name = var.settings[keys(var.settings)[0]].resource_group_name
  identifiers = {
    for key in local.keys:
      key => length(var.global_settings[key].identifier) > 0 ?"-${var.global_settings[key].identifier}" : ""
  }

  topic_region = flatten([
    for key in keys(local.keys) : [
      for topic in local.integration_topics : {
        "key" = key
        "topic" = topic
      }
    ]
  ])
  topic_region_map = {
    for item in local.topic_region:
      "${item.key}:${item.topic}" => {
        "key" = item.key
        "topic" = item.topic
      }
  }
}

resource "azurerm_servicebus_namespace" "service_namespace" {
  for_each            = local.keys
  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-services-namespace"
  resource_group_name = local.resource_group_name
  location            = var.global_settings[each.value].location

  sku = "Standard"

  tags = {
    environment = var.global_settings[each.value].environment
  }
}

resource "azurerm_servicebus_namespace" "integration_namespace" {
  for_each            = local.keys
  name                = "test-${var.global_settings[each.value].environment}${local.identifiers[each.value]}-integration-namespace"
  resource_group_name = local.resource_group_name
  location            = var.global_settings[each.value].location

  sku = "Standard"

  tags = {
    environment = var.global_settings[each.value].environment
  }
}

#for_each = toset(local.integration_topics)
resource "azurerm_servicebus_topic" "integration_topics" {
  for_each            = local.topic_region_map
  name = each.value.topic
  resource_group_name = azurerm_servicebus_namespace.integration_namespace[each.value.key].resource_group_name
  namespace_name      = azurerm_servicebus_namespace.integration_namespace[each.value.key].name

  enable_partitioning = true
}