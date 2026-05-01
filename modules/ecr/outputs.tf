
output "repository_urls" {
  description = "Map of repository name to URL"
  value       = { for k, v in aws_ecr_repository.main : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of repository name to ARN"
  value       = { for k, v in aws_ecr_repository.main : k => v.arn }
}

output "kms_key_arn" {
  description = "KMS key ARN used for ECR encryption"
  value       = aws_kms_key.ecr.arn
}

# FIX: Was values(...)[0] which crashes on empty map — now safe with try()
output "registry_id" {
  description = "ECR registry ID (AWS account ID)"
  value       = try(values(aws_ecr_repository.main)[0].registry_id, null)
}

