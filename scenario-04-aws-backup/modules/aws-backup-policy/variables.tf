variable "name_prefix" {
  description = "Prefix used for Backup vault, plan, and selection names."
  type        = string
}

variable "tags" {
  description = "Tags applied to Backup resources created by this module."
  type        = map(string)
  default     = {}
}

variable "primary_vault_kms_key_arn" {
  description = "KMS key ARN used to encrypt backups in the primary vault."
  type        = string
}

variable "backup_schedule_cron" {
  description = "AWS Backup schedule expression, e.g. cron(0 2 * * ? *)."
  type        = string
  default     = "cron(0 2 * * ? *)"
}

variable "backup_retention_days" {
  description = "Days before deleting recovery points. If cold storage is enabled, must be at least cold_storage_after_days + 90."
  type        = number
  default     = 120
}

variable "cold_storage_after_days" {
  description = "Days before transitioning recovery points to cold storage. Set to null to disable. If set, delete_after must be >= this + 90."
  type        = number
  default     = 30
  nullable    = true
}

variable "enable_continuous_backup" {
  description = "Enable continuous backup (PITR) where supported by the resource type."
  type        = bool
  default     = false
}

variable "selection_owner_tag_value" {
  description = "Required value for the Owner tag on resources selected for backup."
  type        = string
}

variable "backup_iam_role_arn" {
  description = "IAM role ARN assumed by AWS Backup for selections."
  type        = string
}

variable "cross_region_copy" {
  description = "Cross-Region copy into a destination vault (e.g. Prod Ireland)."
  type = object({
    enabled                 = bool
    destination_vault_arn   = string
    retention_days          = number
    cold_storage_after_days = optional(number)
  })
  default = {
    enabled               = false
    destination_vault_arn = ""
    retention_days        = 120
  }
}

variable "cross_account_copy" {
  description = "Cross-Account copy into a destination vault (Backup account)."
  type = object({
    enabled                 = bool
    destination_vault_arn   = string
    retention_days          = number
    cold_storage_after_days = optional(number)
  })
  default = {
    enabled               = false
    destination_vault_arn = ""
    retention_days        = 180
  }
}

variable "vault_lock" {
  description = "AWS Backup Vault Lock (WORM) configuration for the primary vault."
  type = object({
    enabled             = bool
    min_retention_days  = number
    max_retention_days  = optional(number)
    changeable_for_days = optional(number)
  })
  default = {
    enabled             = true
    min_retention_days  = 7
    max_retention_days  = 365
    changeable_for_days = 3
  }
}
