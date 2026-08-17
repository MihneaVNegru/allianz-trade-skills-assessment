terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Prod account — Frankfurt (primary)
provider "aws" {
  region = var.primary_region
}

# Prod account — Ireland (cross-region copy destination)
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

# Backup account — Frankfurt (cross-account copy destination)
provider "aws" {
  alias  = "backup_account"
  region = var.primary_region

  dynamic "assume_role" {
    for_each = var.backup_account_role_arn != null ? [1] : []
    content {
      role_arn = var.backup_account_role_arn
    }
  }
}

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# Destination vaults (Ireland + Backup account) with Vault Lock
# In a real landing zone these often live in separate stacks; kept here so the
# example matches the assessment diagram in one place.
# -----------------------------------------------------------------------------

resource "aws_backup_vault" "ireland" {
  provider = aws.secondary

  name        = "${var.name_prefix}-ireland"
  kms_key_arn = var.secondary_vault_kms_key_arn
  tags        = var.tags
}

resource "aws_backup_vault_lock_configuration" "ireland" {
  provider = aws.secondary

  backup_vault_name   = aws_backup_vault.ireland.name
  min_retention_days  = var.vault_lock_min_retention_days
  max_retention_days  = var.vault_lock_max_retention_days
  changeable_for_days = var.vault_lock_changeable_for_days
}

resource "aws_backup_vault" "backup_account" {
  provider = aws.backup_account

  name        = "${var.name_prefix}-org-backup"
  kms_key_arn = var.cross_account_vault_kms_key_arn
  tags        = var.tags
}

resource "aws_backup_vault_lock_configuration" "backup_account" {
  provider = aws.backup_account

  backup_vault_name   = aws_backup_vault.backup_account.name
  min_retention_days  = var.vault_lock_min_retention_days
  max_retention_days  = var.vault_lock_max_retention_days
  changeable_for_days = var.vault_lock_changeable_for_days
}

# Allow the prod account to copy recovery points into the Backup account vault.
resource "aws_backup_vault_policy" "backup_account" {
  provider = aws.backup_account

  backup_vault_name = aws_backup_vault.backup_account.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowProdAccountCopy"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "backup:CopyIntoBackupVault"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM role used by AWS Backup in the prod account (selection + copies).
data "aws_iam_policy_document" "backup_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "backup" {
  name               = "${var.name_prefix}-aws-backup"
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Needed for S3 — the base backup service role policy does not cover it.
resource "aws_iam_role_policy_attachment" "backup_s3" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_iam_role_policy_attachment" "restore_s3" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
}

module "backup_policy" {
  source = "../../modules/aws-backup-policy"

  name_prefix               = var.name_prefix
  tags                      = var.tags
  primary_vault_kms_key_arn = var.primary_vault_kms_key_arn
  backup_schedule_cron      = var.backup_schedule_cron
  backup_retention_days     = var.backup_retention_days
  cold_storage_after_days   = var.cold_storage_after_days
  selection_owner_tag_value = var.selection_owner_tag_value
  backup_iam_role_arn       = aws_iam_role.backup.arn

  vault_lock = {
    enabled             = true
    min_retention_days  = var.vault_lock_min_retention_days
    max_retention_days  = var.vault_lock_max_retention_days
    changeable_for_days = var.vault_lock_changeable_for_days
  }

  cross_region_copy = {
    enabled                 = true
    destination_vault_arn   = aws_backup_vault.ireland.arn
    retention_days          = var.cross_region_retention_days
    cold_storage_after_days = var.cold_storage_after_days
  }

  cross_account_copy = {
    enabled                 = true
    destination_vault_arn   = aws_backup_vault.backup_account.arn
    retention_days          = var.cross_account_retention_days
    cold_storage_after_days = var.cold_storage_after_days
  }
}
