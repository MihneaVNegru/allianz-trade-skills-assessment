variable "name_prefix" {
  type    = string
  default = "allianz-trade"
}

variable "primary_region" {
  description = "Primary region (Frankfurt in the assessment diagram)."
  type        = string
  default     = "eu-central-1"
}

variable "secondary_region" {
  description = "Cross-region copy destination (Ireland)."
  type        = string
  default     = "eu-west-1"
}

variable "backup_account_role_arn" {
  description = "Optional role in the Backup account for the aws.backup_account provider. Leave null if using same credentials for demos."
  type        = string
  default     = null
  nullable    = true
}

variable "primary_vault_kms_key_arn" {
  description = "KMS key ARN for the primary (Frankfurt) vault."
  type        = string
}

variable "secondary_vault_kms_key_arn" {
  description = "KMS key ARN for the Ireland vault."
  type        = string
}

variable "cross_account_vault_kms_key_arn" {
  description = "KMS key ARN for the Backup account vault."
  type        = string
}

variable "selection_owner_tag_value" {
  description = "Owner tag value required on backed-up resources."
  type        = string
  default     = "owner@eulerhermes.com"
}

variable "backup_schedule_cron" {
  type    = string
  default = "cron(0 2 * * ? *)"
}

variable "backup_retention_days" {
  type    = number
  default = 120
}

variable "cross_region_retention_days" {
  type    = number
  default = 120
}

variable "cross_account_retention_days" {
  type    = number
  default = 180
}

variable "cold_storage_after_days" {
  type    = number
  default = 30
}

variable "vault_lock_min_retention_days" {
  type    = number
  default = 7
}

variable "vault_lock_max_retention_days" {
  type    = number
  default = 365
}

variable "vault_lock_changeable_for_days" {
  description = "Vault Lock cooling-off period before the lock becomes immutable."
  type        = number
  default     = 3
}

variable "tags" {
  type = map(string)
  default = {
    Project = "allianz-trade-skills-assessment"
    Managed = "terraform"
  }
}
