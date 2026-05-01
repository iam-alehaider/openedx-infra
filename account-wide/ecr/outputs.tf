


# account-wide/ecr/outputs.tf

output "repository_urls" {
  description = "Map of repo name → ECR URL (use in k8s image fields)"
  value       = module.ecr.repository_urls
}

output "repository_arns" {
  description = "Map of repo name → ECR ARN"
  value       = module.ecr.repository_arns
}

output "registry_id" {
  description = "ECR registry ID (AWS account ID)"
  value       = module.ecr.registry_id
}

output "kms_key_arn" {
  description = "KMS key ARN used to encrypt ECR images"
  value       = module.ecr.kms_key_arn
}

# Convenience: full image URI for the LMS repo (most commonly referenced)
output "lms_repository_url" {
  description = "ECR URL for the LMS image — openedx/lms"
  value       = module.ecr.repository_urls["lms"]
}

