

output "storage_bucket_name" {
  description = "Name of the OpenEdX application storage bucket"
  value       = aws_s3_bucket.openedx_storage.id
}

output "storage_bucket_arn" {
  description = "ARN of the OpenEdX application storage bucket"
  value       = aws_s3_bucket.openedx_storage.arn
}

output "tf_state_bucket_name" {
  description = "Name of the Terraform state bucket"
  value       = aws_s3_bucket.tf_state.id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking"
  value       = aws_dynamodb_table.tf_locks.name
}

output "app_storage_kms_key_arn" {
  description = "KMS key ARN for application storage bucket"
  value       = aws_kms_key.app_storage.arn
}

output "tf_state_kms_key_arn" {
  description = "KMS key ARN for Terraform state bucket"
  value       = aws_kms_key.tf_state.arn
}

