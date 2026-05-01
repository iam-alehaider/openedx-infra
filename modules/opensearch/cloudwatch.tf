

resource "aws_cloudwatch_log_group" "opensearch" {
  name              = "/aws/opensearch/${local.name}"
  # FIX: Retention now a variable (was hardcoded 14 days)
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

