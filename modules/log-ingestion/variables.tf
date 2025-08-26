variable "subscription_ids" {
  type        = list(string)
  description = "List of Azure subscription IDs to monitor for log ingestion"

  validation {
    condition     = alltrue([for id in var.subscription_ids : can(regex("^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$", id))])
    error_message = "All subscription IDs must be valid UUIDs in the format XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX."
  }
}

variable "app_service_principal_id" {
  type        = string
  description = "Service principal ID of CrowdStrike app to which all the roles will be assigned for log ingestion"

  validation {
    condition     = can(regex("^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$", var.app_service_principal_id))
    error_message = "The object_id must be a valid UUID in the format XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Azure resource group name that will host CrowdStrike log ingestion infrastructure"
}

variable "activity_log_settings" {
  description = "Configuration settings for Azure Activity Log ingestion"
  type = object({
    enabled = bool
    existing_eventhub = object({
      eventhub_resource_id         = string
      eventhub_consumer_group_name = string
    })
  })
  default = {
    enabled = false
    existing_eventhub = {
      eventhub_resource_id         = ""
      eventhub_consumer_group_name = ""
    }
  }
}

variable "entra_id_log_settings" {
  description = "Configuration settings for Microsoft Entra ID log ingestion"
  type = object({
    enabled = bool
    existing_eventhub = object({
      eventhub_resource_id         = string
      eventhub_consumer_group_name = string
    })
  })
  default = {
    enabled = false
    existing_eventhub = {
      eventhub_resource_id         = ""
      eventhub_consumer_group_name = ""
    }
  }
}

variable "diagnostic_log_settings" {
  description = "Configuration settings for Azure Diagnostic Log ingestion"
  type = object({
    enabled = bool
    existing_eventhub = object({
      eventhub_resource_id         = string
      eventhub_consumer_group_name = string
    })
  })
  default = {
    enabled = false
    existing_eventhub = {
      eventhub_resource_id         = ""
      eventhub_consumer_group_name = ""
    }
  }
}

variable "network_log_settings" {
  description = "Configuration settings for Azure Network Log ingestion"
  type = object({
    enabled = bool
    existing_eventhub = object({
      eventhub_resource_id         = string
      eventhub_consumer_group_name = string
    })
  })
  default = {
    enabled = false
    existing_eventhub = {
      eventhub_resource_id         = ""
      eventhub_consumer_group_name = ""
    }
  }
}

variable "env" {
  description = "Environment label (for example, prod, stag, dev) used for resource naming and tagging. Helps distinguish between different deployment environments. Limited to 4 alphanumeric characters for compatibility with resource naming restrictions."
  default     = "prod"
  type        = string
}

variable "location" {
  description = "Azure location (region) where global resources such as role definitions and event hub will be deployed. These tenant-wide resources only need to be created once regardless of how many subscriptions are monitored."
  default     = "westus"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix to be added to all created resource names for identification"
  default     = ""
  type        = string
}

variable "resource_suffix" {
  description = "Suffix to be added to all created resource names for identification"
  default     = ""
  type        = string
}

variable "tags" {
  description = "Tags to be applied to all resources created by this module"
  default = {
    CSTagVendor : "CrowdStrike"
  }
  type = map(string)
}