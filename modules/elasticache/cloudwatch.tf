

resource "aws_cloudwatch_log_group" "redis_slow" {
  name              = "/aws/elasticache/${local.name}/slow-logs"
  # FIX: Retention is now a variable (was hardcoded to 7, too low for debugging prod issues)
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

