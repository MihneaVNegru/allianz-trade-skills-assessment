output "primary_vault_arn" {
  value = module.backup_policy.primary_vault_arn
}

output "backup_plan_arn" {
  value = module.backup_policy.backup_plan_arn
}

output "ireland_vault_arn" {
  value = aws_backup_vault.ireland.arn
}

output "backup_account_vault_arn" {
  value = aws_backup_vault.backup_account.arn
}

output "backup_role_arn" {
  value = aws_iam_role.backup.arn
}
