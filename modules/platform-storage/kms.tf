

# FIX: Separate KMS keys for app storage and Terraform state
# Previously: single shared key — if compromised or deleted, BOTH datasets lost
# Now: separate blast radius per domain

resource "aws_kms_key" "app_storage" {
  description             = "S3 KMS key for ${local.name} application storage"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = merge(local.tags, { Name = "${local.name}-app-storage-kms" })
}

resource "aws_kms_alias" "app_storage" {
  name          = "alias/${local.name}-app-storage"
  target_key_id = aws_kms_key.app_storage.key_id
}

resource "aws_kms_key" "tf_state" {
  description             = "S3 KMS key for ${local.name} Terraform state"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = merge(local.tags, { Name = "${local.name}-tf-state-kms" })
}

resource "aws_kms_alias" "tf_state" {
  name          = "alias/${local.name}-tf-state"
  target_key_id = aws_kms_key.tf_state.key_id
}

