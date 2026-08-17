locals {
  copy_actions = concat(
    var.cross_region_copy.enabled ? [
      {
        destination_vault_arn = var.cross_region_copy.destination_vault_arn
        delete_after          = var.cross_region_copy.retention_days
        cold_storage_after    = try(var.cross_region_copy.cold_storage_after_days, null)
      }
    ] : [],
    var.cross_account_copy.enabled ? [
      {
        destination_vault_arn = var.cross_account_copy.destination_vault_arn
        delete_after          = var.cross_account_copy.retention_days
        cold_storage_after    = try(var.cross_account_copy.cold_storage_after_days, null)
      }
    ] : []
  )
}

# -----------------------------------------------------------------------------
# Primary vault + Vault Lock (WORM)
# -----------------------------------------------------------------------------

resource "aws_backup_vault" "primary" {
  name        = "${var.name_prefix}-primary"
  kms_key_arn = var.primary_vault_kms_key_arn
  tags        = var.tags
}

resource "aws_backup_vault_lock_configuration" "primary" {
  count = var.vault_lock.enabled ? 1 : 0

  backup_vault_name   = aws_backup_vault.primary.name
  min_retention_days  = var.vault_lock.min_retention_days
  max_retention_days  = try(var.vault_lock.max_retention_days, null)
  changeable_for_days = try(var.vault_lock.changeable_for_days, null)
}

# -----------------------------------------------------------------------------
# Backup plan — frequency, retention, encryption (vault KMS), X-region / X-account copy
# -----------------------------------------------------------------------------

resource "aws_backup_plan" "this" {
  name = "${var.name_prefix}-plan"
  tags = var.tags

  rule {
    rule_name                = "${var.name_prefix}-daily"
    target_vault_name        = aws_backup_vault.primary.name
    schedule                 = var.backup_schedule_cron
    enable_continuous_backup = var.enable_continuous_backup

    lifecycle {
      cold_storage_after = var.cold_storage_after_days
      delete_after       = var.backup_retention_days
    }

    dynamic "copy_action" {
      for_each = local.copy_actions
      content {
        destination_vault_arn = copy_action.value.destination_vault_arn

        lifecycle {
          cold_storage_after = copy_action.value.cold_storage_after
          delete_after       = copy_action.value.delete_after
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Resource selection — ToBackup = true AND Owner = <owner email>
# Use condition (AND). Multiple selection_tag blocks are OR and would be wrong here.
# -----------------------------------------------------------------------------

resource "aws_backup_selection" "tagged" {
  name         = "${var.name_prefix}-selection"
  iam_role_arn = var.backup_iam_role_arn
  plan_id      = aws_backup_plan.this.id
  resources    = ["*"]

  condition {
    string_equals {
      key   = "aws:ResourceTag/ToBackup"
      value = "true"
    }

    string_equals {
      key   = "aws:ResourceTag/Owner"
      value = var.selection_owner_tag_value
    }
  }
}
