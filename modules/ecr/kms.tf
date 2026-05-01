# FIX: Customer-managed KMS key for ECR encryption
# Was using AWS-managed default key — no rotation control, no cross-account sharing control

resource "aws_kms_key" "ecr" {
  description             = "ECR encryption key for ${local.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = merge(local.tags, { Name = "${local.name}-ecr-kms" })
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/${local.name}-ecr"
  target_key_id = aws_kms_key.ecr.key_id
}

