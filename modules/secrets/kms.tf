# FIX: Dedicated KMS key for Secrets Manager
# Separates blast radius from S3/RDS/EFS KMS keys

resource "aws_kms_key" "secrets" {
  description             = "Secrets Manager encryption key for ${local.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = merge(local.tags, { Name = "${local.name}-secrets-kms" })
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.name}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

