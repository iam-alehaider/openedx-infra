
# FIX: Removed origin_verify_value output — even with sensitive = true, the value
# is stored in Terraform state and can leak in CI logs. Consumers must read
# the secret directly from Secrets Manager at runtime using the ARN below.

output "redis_secret_arn" {
  description = "ARN of the Redis auth token secret in Secrets Manager"
  value       = aws_secretsmanager_secret.redis.arn
}

output "opensearch_secret_arn" {
  description = "ARN of the OpenSearch master password secret in Secrets Manager"
  value       = aws_secretsmanager_secret.opensearch.arn
}

output "origin_verify_secret_arn" {
  description = "ARN of the CloudFront origin-verify secret in Secrets Manager"
  value       = aws_secretsmanager_secret.origin_verify.arn
}

output "kms_key_arn" {
  description = "KMS key ARN used to encrypt all secrets in this module"
  value       = aws_kms_key.secrets.arn
}

