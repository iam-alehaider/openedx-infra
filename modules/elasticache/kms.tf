

# FIX: Customer-managed KMS key for Redis encryption at rest
# Gives rotation control and fine-grained access control

resource "aws_kms_key" "redis" {
  description             = "Redis encryption key for ${local.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = merge(local.tags, { Name = "${local.name}-redis-kms" })
}

resource "aws_kms_alias" "redis" {
  name          = "alias/${local.name}-redis"
  target_key_id = aws_kms_key.redis.key_id
}

