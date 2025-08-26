data "azurerm_client_config" "current" {}

locals {
  subscriptions               = toset(concat(var.cs_infra_subscription_id == "" ? [] : [var.cs_infra_subscription_id], var.subscription_ids))
  management_groups           = toset(length(var.subscription_ids) == 0 && length(var.management_group_ids) == 0 ? [data.azurerm_client_config.current.tenant_id] : var.management_group_ids)
  env                         = var.env == "" ? "" : "-${var.env}"
  should_deploy_log_ingestion = var.enable_realtime_visibility

  microsoft_graph_permission_ids = var.microsoft_graph_permission_ids != null ? var.microsoft_graph_permission_ids : [
    "9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30", # Application.Read.All (Role)
    "98830695-27a2-44f7-8c18-0c3ebc9698f6", # GroupMember.Read.All (Role)
    "246dd0d5-5bd0-4def-940b-0421030a5b68", # Policy.Read.All (Role)
    "230c1aed-a721-4c5d-9cb4-a90514e508ef", # Reports.Read.All (Role)
    "483bed4a-2ad3-4361-a73b-c83ccdbdc53c", # RoleManagement.Read.Directory (Role)
    "df021288-bdef-4463-88db-98f22de89214"  # User.Read.All (Role)
  ]
  service_principal_object_id = var.create_service_principal ? module.service_principal[0].object_id : var.existing_service_principal_object_id
}

# Comment out this block only when crowdstrike provider is enabled
# Note Crowdstrike Provider authenticates client ID and secrets at the time of running terraform plan/apply


# resource "crowdstrike_cloud_azure_tenant" "this" {
#   count = var.enable_crowdstrike_provider_resources ? 1 : 0

#   tenant_id                      = data.azurerm_client_config.current.tenant_id
#   microsoft_graph_permission_ids = local.microsoft_graph_permission_ids
#   realtime_visibility = {
#     enabled = var.enable_realtime_visibility
#   }
#   cs_infra_subscription_id = var.cs_infra_subscription_id
#   cs_infra_location        = var.location
#   resource_name_prefix     = var.resource_prefix
#   resource_name_suffix     = var.resource_suffix
#   environment              = var.env
#   management_group_ids     = var.management_group_ids
#   subscription_ids         = var.subscription_ids
#   tags                     = var.tags
# }

module "service_principal" {
  count  = var.create_service_principal ? 1 : 0
  source = "./modules/service-principal/"

  azure_client_id                = "0805b105-a007-49b3-b575-14eed38fc1d0"
  microsoft_graph_permission_ids = local.microsoft_graph_permission_ids
}

module "asset_inventory" {
  source = "./modules/asset-inventory/"

  management_group_ids     = local.management_groups
  subscription_ids         = local.subscriptions
  app_service_principal_id = local.service_principal_object_id
  resource_prefix          = var.resource_prefix
  resource_suffix          = var.resource_suffix
  enable_app_service_monitoring = var.enable_app_service_monitoring

  depends_on = [
    module.service_principal
  ]
}

module "deployment_scope" {
  source = "./modules/deployment-scope"

  management_group_ids = local.management_groups
  subscription_ids     = local.subscriptions
}

module "log_ingestion" {
  count  = local.should_deploy_log_ingestion ? 1 : 0
  source = "./modules/log-ingestion/"

  subscription_ids         = module.deployment_scope.all_active_subscription_ids
  app_service_principal_id = local.service_principal_object_id
  resource_group_name      = var.resource_group_name
  activity_log_settings    = var.log_ingestion_settings.activity_log
  entra_id_log_settings    = var.log_ingestion_settings.entra_id_log
  diagnostic_log_settings  = var.log_ingestion_settings.diagnostic_log
  network_log_settings     = var.log_ingestion_settings.network_log
  env                      = var.env
  location                 = var.location
  resource_prefix          = var.resource_prefix
  resource_suffix          = var.resource_suffix
  tags                     = var.tags

  depends_on = [
    module.deployment_scope
  ]
}
