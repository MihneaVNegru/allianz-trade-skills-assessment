# Scenario 4 — Backup policy with AWS Backup (Terraform)

Implements the assessment design: a reusable Backup module for the **Prod / Frankfurt** plan + vault, with **cross-region** and **cross-account** copy targets and **Vault Lock (WORM)**.

> Illustrative module for skills validation — not a full production landing-zone package.

## Requirement → code map

| Requirement | Where it lives |
|-------------|----------------|
| Plan: frequency | `backup_schedule_cron` → `aws_backup_plan` rule `schedule` |
| Plan: retention | `backup_retention_days` / cold storage → rule `lifecycle` |
| Plan: encryption | `primary_vault_kms_key_arn` on `aws_backup_vault.primary` |
| Selection: `ToBackup = true` + `Owner = <email>` (AND) | `condition { string_equals ... }` on `aws_backup_selection` |
| Cross-Region copy | `cross_region_copy` → plan rule `copy_action` |
| Cross-Account copy | `cross_account_copy` → second `copy_action` + example vault policy |
| WORM / Vault Lock | `aws_backup_vault_lock_configuration` on primary (module) and destination vaults (example) |

## Layout

```
scenario-04-aws-backup/
  modules/aws-backup-policy/   # reusable module (primary vault, plan, selection, copies)
  examples/basic/              # wires Ireland + Backup-account vaults and calls the module
```

## Usage

```bash
cd examples/basic
cp terraform.tfvars.example terraform.tfvars
# edit KMS key ARNs / optional backup account role
terraform init
terraform plan
```

### Module call (sketch)

```hcl
module "backup_policy" {
  source = "../../modules/aws-backup-policy"

  name_prefix               = "allianz-trade"
  primary_vault_kms_key_arn = var.primary_vault_kms_key_arn
  selection_owner_tag_value = "owner@eulerhermes.com"
  backup_iam_role_arn       = aws_iam_role.backup.arn

  backup_schedule_cron    = "cron(0 2 * * ? *)"
  backup_retention_days   = 120
  cold_storage_after_days = 30

  vault_lock = {
    enabled             = true
    min_retention_days  = 7
    max_retention_days  = 365
    changeable_for_days = 3
  }

  cross_region_copy = {
    enabled               = true
    destination_vault_arn = aws_backup_vault.ireland.arn
    retention_days        = 120
  }

  cross_account_copy = {
    enabled               = true
    destination_vault_arn = aws_backup_vault.backup_account.arn
    retention_days        = 180
  }
}
```

Tagged resources are selected when **both** tags match (AND via `condition`, not `selection_tag`):

- `ToBackup = true`
- `Owner = <owner@eulerhermes.com>` (configurable)

## Notes for reviewers

- Destination vaults (Ireland, Backup account) are created in the **example** so multi-region / multi-account providers stay outside the core module; the module consumes their ARNs for `copy_action` blocks.
- Cross-account copy needs a vault policy allowing `backup:CopyIntoBackupVault` from the source account (included in the example).
- The example attaches the S3 backup/restore managed policies as well — the base Backup service role alone skips S3.
- Vault Lock’s `changeable_for_days` is a cooling-off window — after that, lock settings become immutable; use carefully in real accounts.
- If cold storage is enabled, AWS Backup requires `delete_after >= cold_storage_after + 90` (example uses 30 → 120).
