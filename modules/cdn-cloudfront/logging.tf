data "aws_caller_identity" "current" {}


#=======================================================================
# CloudFront access log bucket (us-east-1 required for CloudFront logs)
#=======================================================================

resource "aws_s3_bucket" "cf_logs" {
  provider      = aws.us_east_1
  bucket        = "${local.name}-cloudfront-logs"
  force_destroy = var.environment != "prod"
  tags          = merge(local.tags, { Name = "${local.name}-cloudfront-logs" })
}

resource "aws_s3_bucket_ownership_controls" "cf_logs" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.cf_logs.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_public_access_block" "cf_logs" {
  provider                = aws.us_east_1
  bucket                  = aws_s3_bucket.cf_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cf_logs" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.cf_logs.id

  rule {
    id     = "expire-cf-logs"
    status = "Enabled"
    expiration {
      days = var.cf_log_retention_days
    }
  }
}


resource "aws_s3_bucket_policy" "cf_logs" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.cf_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontLogDelivery"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cf_logs.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}


#=======================================================================
# P1 ── WAF log bucket (S3, separate from CloudFront access logs)
#       Receives logs from Kinesis Firehose. Used as SIEM source.
#       Partitioned by year/month for Athena / OpenSearch querying.
#=======================================================================

resource "aws_s3_bucket" "waf_logs" {
  provider      = aws.us_east_1
  bucket        = "${local.name}-waf-logs"
  force_destroy = var.environment != "prod"
  tags          = merge(local.tags, { Name = "${local.name}-waf-logs" })
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  provider                = aws.us_east_1
  bucket                  = aws_s3_bucket.waf_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "waf_logs" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.waf_logs.id

  rule {
    id     = "expire-waf-logs"
    status = "Enabled"
    expiration {
      days = var.waf_s3_log_retention_days
    }
  }
}

#=======================================================================
# P1 ── IAM role for Kinesis Firehose → S3 (+ optional OpenSearch)
#=======================================================================

data "aws_iam_policy_document" "firehose_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "firehose_waf" {
  provider           = aws.us_east_1
  name               = "${local.name}-firehose-waf"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "firehose_waf" {
  # S3 write permissions
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]
    resources = [
      aws_s3_bucket.waf_logs.arn,
      "${aws_s3_bucket.waf_logs.arn}/*",
    ]
  }

  # CloudWatch Logs for Firehose delivery errors
  statement {
    actions = [
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:us-east-1:*:log-group:/aws/kinesisfirehose/*:*"]
  }

  # OpenSearch write permissions (only used when enable_opensearch = true)
  dynamic "statement" {
    for_each = local.enable_opensearch ? [1] : []
    content {
      actions = [
        "es:DescribeElasticsearchDomain",
        "es:DescribeElasticsearchDomains",
        "es:DescribeElasticsearchDomainConfig",
        "es:ESHttpPost",
        "es:ESHttpPut",
      ]
      resources = [
        "arn:aws:es:us-east-1:*:domain/*",
      ]
    }
  }
}

resource "aws_iam_role_policy" "firehose_waf" {
  provider = aws.us_east_1
  name     = "${local.name}-firehose-waf-policy"
  role     = aws_iam_role.firehose_waf.id
  policy   = data.aws_iam_policy_document.firehose_waf.json
}

#=======================================================================
# P1 ── Kinesis Data Firehose: WAF logs → S3 (partitioned by date)
#       Stream name MUST start with "aws-waf-logs-" per AWS requirement.
#       Buffering: 5 min / 64 MB — balances cost vs alert latency.
#       GZIP compression reduces S3 storage ~80%.
#
#       Optional: if opensearch_endpoint is set, also delivers to
#       OpenSearch for real-time dashboards and alerting.
#=======================================================================

resource "aws_kinesis_firehose_delivery_stream" "waf" {
  provider    = aws.us_east_1
  # Name MUST start with "aws-waf-logs-" — AWS enforces this for WAF logging
  name        = "aws-waf-logs-${local.name}-firehose"
  destination = local.enable_opensearch ? "opensearch" : "extended_s3"
  tags        = local.tags

  #----------------------------------------------------------------------
  # Path A: S3 only (default — no opensearch_endpoint set)
  #----------------------------------------------------------------------
  dynamic "extended_s3_configuration" {
    for_each = local.enable_opensearch ? [] : [1]
    content {
      role_arn           = aws_iam_role.firehose_waf.arn
      bucket_arn         = aws_s3_bucket.waf_logs.arn
      buffering_interval = 300  # seconds — 5 min
      buffering_size     = 64   # MB
      compression_format = "GZIP"

      # Hive-style partitioning for Athena queries
      prefix              = "waf-logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
      error_output_prefix = "waf-logs-errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/"

      cloudwatch_logging_options {
        enabled         = true
        log_group_name  = "/aws/kinesisfirehose/${local.name}-waf"
        log_stream_name = "S3Delivery"
      }
    }
  }

  #----------------------------------------------------------------------
  # Path B: OpenSearch + S3 backup (when opensearch_endpoint is set)
  #         S3 backup = failed documents only (avoids double-storing)
  #----------------------------------------------------------------------
  
  dynamic "opensearch_configuration" {
    for_each = local.enable_opensearch ? [1] : []
    content {
      role_arn              = aws_iam_role.firehose_waf.arn
      domain_arn = "arn:aws:es:us-east-1:${data.aws_caller_identity.current.account_id}:domain/${var.opensearch_domain_name}"
      index_name            = "waf-logs"
      index_rotation_period = "OneMonth"
      buffering_interval    = 60
      buffering_size        = 5

      s3_backup_mode = "FailedDocumentsOnly"

      s3_configuration {
        role_arn           = aws_iam_role.firehose_waf.arn
        bucket_arn         = aws_s3_bucket.waf_logs.arn
        buffering_interval = 300
        buffering_size     = 64
        compression_format = "GZIP"
        prefix             = "waf-logs-backup/"
      }

      cloudwatch_logging_options {
        enabled         = true
        log_group_name  = "/aws/kinesisfirehose/${local.name}-waf"
        log_stream_name = "OpenSearchDelivery"
      }
    }
  }

}

#=======================================================================
# P1 ── WAF logging configuration: Firehose (replaces CloudWatch-only)
#       CloudWatch log group is retained for console dashboards / metric
#       filters; Firehose handles the SIEM/alerting pipeline.
#=======================================================================

resource "aws_wafv2_web_acl_logging_configuration" "cloudfront" {
  provider = aws.us_east_1
  # Firehose ARN used for structured log delivery to S3 / OpenSearch
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf.arn]
  resource_arn            = aws_wafv2_web_acl.cloudfront.arn

  # Optional: redact sensitive field values from WAF logs
  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
  redacted_fields {
    single_header {
      name = "x-origin-verify"
    }
  }
}


#=======================================================================
# P1 ── CloudWatch metric alarms for anomaly detection
#       These fire on WAF sampled request metrics, which are always
#       published regardless of the log destination.
#=======================================================================

resource "aws_cloudwatch_metric_alarm" "waf_blocked_spike" {
  provider            = aws.us_east_1
  alarm_name          = "${local.name}-waf-block-spike"
  alarm_description   = "WAF blocked requests spiked — possible attack or misconfiguration"
  namespace           = "AWS/WAFV2"
  metric_name         = "BlockedRequests"
  dimensions = {
    WebACL = aws_wafv2_web_acl.cloudfront.name
    Region = "us-east-1"
    Rule   = "ALL"
  }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 500
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  # ADD THESE TWO LINES:
  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  tags          = local.tags
}

resource "aws_cloudwatch_metric_alarm" "waf_bot_blocked" {
  count               = var.enable_bot_control ? 1 : 0
  provider            = aws.us_east_1
  alarm_name          = "${local.name}-waf-bot-spike"
  alarm_description   = "Bot Control blocked requests spiked — review traffic source"
  namespace           = "AWS/WAFV2"
  metric_name         = "BlockedRequests"
  dimensions = {
    WebACL = aws_wafv2_web_acl.cloudfront.name
    Region = "us-east-1"
    Rule   = "BotControl"
  }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 200
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  # ADD THESE TWO LINES:
  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  tags          = local.tags
}

resource "aws_cloudwatch_metric_alarm" "waf_login_rate" {
  provider            = aws.us_east_1
  alarm_name          = "${local.name}-waf-login-rate-spike"
  alarm_description   = "Login rate limit triggered repeatedly — credential stuffing likely"
  namespace           = "AWS/WAFV2"
  metric_name         = "BlockedRequests"
  dimensions = {
    WebACL = aws_wafv2_web_acl.cloudfront.name
    Region = "us-east-1"
    Rule   = "LoginRateLimit"
  }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 10
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  # ADD THESE TWO LINES:
  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  tags          = local.tags
}
