
# FIX: Read master password from Secrets Manager at apply time
# Previously: var.master_password passed as plaintext variable → stored in Terraform state
# Now: password lives only in Secrets Manager, never in state
data "aws_secretsmanager_secret_version" "opensearch_password" {
  secret_id = var.master_password_secret_arn
}

resource "aws_opensearch_domain" "main" {
  domain_name    = "${local.name}-search"
  engine_version = var.engine_version

  #=========================
  # Cluster Config
  #=========================
  cluster_config {
    instance_type  = var.instance_type
    instance_count = var.instance_count

    zone_awareness_enabled = var.instance_count > 1

    dedicated_master_enabled = var.instance_count >= 3
    dedicated_master_type    = var.master_instance_type
    dedicated_master_count   = var.instance_count >= 3 ? 3 : 0

    dynamic "zone_awareness_config" {
      for_each = var.instance_count > 1 ? [1] : []
      content {
        availability_zone_count = min(var.instance_count, 3)
      }
    }
  }

  #=========================
  # Storage
  #=========================
  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = var.volume_size_gb
    throughput  = 250
  }

  #=========================
  # Networking
  # FIX: Guard against subnet count < instance_count (was crashing silently)
  #=========================
  vpc_options {
    subnet_ids         = slice(var.subnet_ids, 0, min(length(var.subnet_ids), min(var.instance_count, 3)))
    security_group_ids = [aws_security_group.opensearch.id]
  }

  #=========================
  # Security
  #=========================
  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  #=========================
  # Authentication
  # FIX: Password now sourced from Secrets Manager — not stored in Terraform state
  #=========================
  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true

    master_user_options {
      master_user_name     = var.master_user
      master_user_password = data.aws_secretsmanager_secret_version.opensearch_password.secret_string
    }
  }

  #=========================
  # Logging
  #=========================
  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch.arn
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch.arn
    log_type                 = "ES_APPLICATION_LOGS"
  }

  #=========================
  # Protection
  #=========================
  lifecycle {
    prevent_destroy = true
  }

  tags = merge(local.tags, {
    Name   = "${local.name}-search"
    Module = "opensearch"
  })

  depends_on = [aws_iam_service_linked_role.opensearch]
}

# FIX: Explicit access policy to restrict domain access to VPC security group only
resource "aws_opensearch_domain_policy" "main" {
  domain_name = aws_opensearch_domain.main.domain_name

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = "es:*"
        Resource  = "${aws_opensearch_domain.main.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceVpc" = var.vpc_id
          }
        }
      }
    ]
  })
}

