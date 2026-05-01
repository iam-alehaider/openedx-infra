

# FIX: Use customer-managed KMS key instead of AWS default key
# Gives key rotation control, fine-grained access, and better compliance posture

resource "aws_kms_key" "rds" {
  description             = "RDS encryption key for ${local.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = merge(local.tags, { Name = "${local.name}-rds-kms" })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.name}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

