locals {
  activity_log_diagnostic_settings_default_name   = "${var.resource_prefix}diag-cslogact${local.env}${var.resource_suffix}"
  entra_id_log_diagnostic_settings_default_name   = "${var.resource_prefix}diag-cslogentid${local.env}${var.resource_suffix}"
  diagnostic_log_diagnostic_settings_default_name = "${var.resource_prefix}diag-cslogdiag${local.env}${var.resource_suffix}"
  network_log_diagnostic_settings_default_name    = "${var.resource_prefix}diag-cslognet${local.env}${var.resource_suffix}"
  subscription_scopes                              = [for id in var.subscription_ids : "/subscriptions/${id}"]
  env                                              = var.env == "" ? "" : "-${var.env}"
  
  # Event Hub IDs and Consumer Groups - Only for existing Event Hubs
  activity_log_eventhub_id                  = var.activity_log_settings.enabled ? var.activity_log_settings.existing_eventhub.eventhub_resource_id : ""
  activity_log_eventhub_consumer_group_name = var.activity_log_settings.enabled ? var.activity_log_settings.existing_eventhub.eventhub_consumer_group_name : ""
  
  entra_id_log_eventhub_id                  = var.entra_id_log_settings.enabled ? var.entra_id_log_settings.existing_eventhub.eventhub_resource_id : ""
  entra_id_log_eventhub_consumer_group_name = var.entra_id_log_settings.enabled ? var.entra_id_log_settings.existing_eventhub.eventhub_consumer_group_name : ""
  
  diagnostic_log_eventhub_id                = var.diagnostic_log_settings.enabled ? var.diagnostic_log_settings.existing_eventhub.eventhub_resource_id : ""
  diagnostic_log_eventhub_consumer_group_name = var.diagnostic_log_settings.enabled ? var.diagnostic_log_settings.existing_eventhub.eventhub_consumer_group_name : ""
  
  network_log_eventhub_id                   = var.network_log_settings.enabled ? var.network_log_settings.existing_eventhub.eventhub_resource_id : ""
  network_log_eventhub_consumer_group_name  = var.network_log_settings.enabled ? var.network_log_settings.existing_eventhub.eventhub_consumer_group_name : ""

  # Parse existing Event Hub resource IDs to extract resource group info
  parsed_existing_activity_log_eventhub_id    = var.activity_log_settings.enabled ? provider::azurerm::parse_resource_id(var.activity_log_settings.existing_eventhub.eventhub_resource_id) : null
  parsed_existing_entra_id_log_eventhub_id    = var.entra_id_log_settings.enabled ? provider::azurerm::parse_resource_id(var.entra_id_log_settings.existing_eventhub.eventhub_resource_id) : null
  parsed_existing_diagnostic_log_eventhub_id  = var.diagnostic_log_settings.enabled ? provider::azurerm::parse_resource_id(var.diagnostic_log_settings.existing_eventhub.eventhub_resource_id) : null
  parsed_existing_network_log_eventhub_id     = var.network_log_settings.enabled ? provider::azurerm::parse_resource_id(var.network_log_settings.existing_eventhub.eventhub_resource_id) : null

  # Resource Group IDs for role assignments
  activity_log_eventhub_resource_group_id   = var.activity_log_settings.enabled ? "/subscriptions/${local.parsed_existing_activity_log_eventhub_id.subscription_id}/resourceGroups/${local.parsed_existing_activity_log_eventhub_id.resource_group_name}" : ""
  entra_id_log_eventhub_resource_group_id   = var.entra_id_log_settings.enabled ? "/subscriptions/${local.parsed_existing_entra_id_log_eventhub_id.subscription_id}/resourceGroups/${local.parsed_existing_entra_id_log_eventhub_id.resource_group_name}" : ""
  diagnostic_log_eventhub_resource_group_id = var.diagnostic_log_settings.enabled ? "/subscriptions/${local.parsed_existing_diagnostic_log_eventhub_id.subscription_id}/resourceGroups/${local.parsed_existing_diagnostic_log_eventhub_id.resource_group_name}" : ""
  network_log_eventhub_resource_group_id    = var.network_log_settings.enabled ? "/subscriptions/${local.parsed_existing_network_log_eventhub_id.subscription_id}/resourceGroups/${local.parsed_existing_network_log_eventhub_id.resource_group_name}" : ""
}

data "azurerm_client_config" "this" {}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

# Role assignments for CrowdStrike service principal to access existing Event Hubs
resource "azurerm_role_assignment" "activity_log_event_hub_data_receiver" {
  count                            = var.activity_log_settings.enabled ? 1 : 0
  scope                            = local.activity_log_eventhub_resource_group_id
  role_definition_name             = "Azure Event Hubs Data Receiver"
  principal_id                     = var.app_service_principal_id
  skip_service_principal_aad_check = false

  depends_on = [data.azurerm_resource_group.this]
}

resource "azurerm_role_assignment" "entra_id_eventhub_data_receiver" {
  count                            = var.entra_id_log_settings.enabled && local.activity_log_eventhub_resource_group_id != local.entra_id_log_eventhub_resource_group_id ? 1 : 0
  scope                            = local.entra_id_log_eventhub_resource_group_id
  role_definition_name             = "Azure Event Hubs Data Receiver"
  principal_id                     = var.app_service_principal_id
  skip_service_principal_aad_check = false

  depends_on = [data.azurerm_resource_group.this]
}

resource "azurerm_role_assignment" "diagnostic_log_eventhub_data_receiver" {
  count                            = var.diagnostic_log_settings.enabled ? 1 : 0
  scope                            = local.diagnostic_log_eventhub_resource_group_id
  role_definition_name             = "Azure Event Hubs Data Receiver"
  principal_id                     = var.app_service_principal_id
  skip_service_principal_aad_check = false

  depends_on = [data.azurerm_resource_group.this]
}

resource "azurerm_role_assignment" "network_log_eventhub_data_receiver" {
  count                            = var.network_log_settings.enabled ? 1 : 0
  scope                            = local.network_log_eventhub_resource_group_id
  role_definition_name             = "Azure Event Hubs Data Receiver"
  principal_id                     = var.app_service_principal_id
  skip_service_principal_aad_check = false

  depends_on = [data.azurerm_resource_group.this]
}