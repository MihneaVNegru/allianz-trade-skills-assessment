output "primary_vault_arn" {
  description = "ARN of the primary Backup vault."
  value       = aws_backup_vault.primary.arn
}

output "primary_vault_name" {
  description = "Name of the primary Backup vault."
  value       = aws_backup_vault.primary.name
}

output "backup_plan_id" {
  description = "ID of the Backup plan."
  value       = aws_backup_plan.this.id
}

output "backup_plan_arn" {
  description = "ARN of the Backup plan."
  value       = aws_backup_plan.this.arn
}

output "backup_selection_id" {
  description = "ID of the tag-based Backup selection."
  value       = aws_backup_selection.tagged.id
}
