# NOTE: RDS master password is managed directly by RDS via manage_master_user_password = true.
# The RDS module outputs master_user_secret_arn for that secret.
# This module manages secrets for services that do NOT have AWS-native rotation:
# Redis auth token, OpenSearch password, and CloudFront origin-verify header.

# ── Redis Auth Token ──
resource "aws_secretsmanager_secret" "redis" {
  name                    = "${local.name}/redis/auth-token"
  description             = "Redis AUTH token for ${local.name}"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(local.tags, { Name = "${local.name}-redis-secret" })

  lifecycle {
    prevent_destroy = true
  }
}

# ── OpenSearch Master Password ──
resource "aws_secretsmanager_secret" "opensearch" {
  name                    = "${local.name}/opensearch/master-password"
  description             = "OpenSearch master password for ${local.name}"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(local.tags, { Name = "${local.name}-opensearch-secret" })

  lifecycle {
    prevent_destroy = true
  }
}

# ── CloudFront Origin Verify Secret ──
resource "aws_secretsmanager_secret" "origin_verify" {
  name                    = "${local.name}/cloudfront/origin-verify"
  description             = "X-Origin-Verify header secret for CloudFront → ALB"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = 7

  tags = merge(local.tags, { Name = "${local.name}-origin-verify-secret" })

  lifecycle {
    prevent_destroy = true
  }
}

# Auto-generate a random value for CloudFront origin verify
resource "random_password" "origin_verify" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret_version" "origin_verify" {
  secret_id     = aws_secretsmanager_secret.origin_verify.id
  secret_string = random_password.origin_verify.result
}

# ── IAM Resource-Based Policies ──
# Restrict who can read each secret (add your EKS IRSA role ARNs after cluster creation)

resource "aws_secretsmanager_secret_policy" "redis" {
  secret_arn = aws_secretsmanager_secret.redis.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyNonTLS"
        Effect = "Deny"
        Principal = { AWS = "*" }
        Action    = "secretsmanager:GetSecretValue"
        Resource  = "*"
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
      {
        Sid    = "AllowAuthorizedRoles"
        Effect = "Allow"
        Principal = {
          AWS = length(var.redis_reader_role_arns) > 0
            ? var.redis_reader_role_arns
            : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/PLACEHOLDER-set-redis_reader_role_arns"]
        }

        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_secretsmanager_secret_policy" "opensearch" {
  secret_arn = aws_secretsmanager_secret.opensearch.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyNonTLS"
        Effect = "Deny"
        Principal = { AWS = "*" }
        Action    = "secretsmanager:GetSecretValue"
        Resource  = "*"
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
      {
        Sid    = "AllowAuthorizedRoles"
        Effect = "Allow"
        Principal = {
          AWS = length(var.opensearch_reader_role_arns) > 0
            ? var.opensearch_reader_role_arns
            : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/PLACEHOLDER-set-opensearch_reader_role_arns"]
        }   
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = "*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

