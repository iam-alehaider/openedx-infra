data "aws_caller_identity" "current" {}

# ── SNS Topic for all alarms ──
resource "aws_sns_topic" "alarms" {
  name = "${local.name}-alarms"
  tags = local.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

#==============================
# RDS Alarms
#==============================

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU above 80% for 3 consecutive minutes"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  dimensions          = { DBInstanceIdentifier = var.rds_identifier }
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${local.name}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240 # 10 GB in bytes
  alarm_description   = "RDS free storage below 10 GB"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  dimensions          = { DBInstanceIdentifier = var.rds_identifier }
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${local.name}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 400
  alarm_description   = "RDS connections above 400 (limit is 500)"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions          = { DBInstanceIdentifier = var.rds_identifier }
  tags                = local.tags
}

#==============================
# Redis Alarms
#==============================

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "${local.name}-redis-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Redis memory usage above 80%"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  dimensions          = { ReplicationGroupId = var.redis_replication_id }
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "${local.name}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Redis engine CPU above 70%"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions          = { ReplicationGroupId = var.redis_replication_id }
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "redis_replication_lag" {
  alarm_name          = "${local.name}-redis-replication-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicationLag"
  namespace           = "AWS/ElastiCache"
  period              = 60
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "Redis replication lag above 30 seconds"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions          = { ReplicationGroupId = var.redis_replication_id }
  tags                = local.tags
}

#==============================
# OpenSearch Alarms (conditional)
#==============================

resource "aws_cloudwatch_metric_alarm" "opensearch_cluster_red" {
  count               = var.enable_opensearch_alarms ? 1 : 0
  alarm_name          = "${local.name}-opensearch-cluster-red"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ClusterStatus.red"
  namespace           = "AWS/ES"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "OpenSearch cluster status is RED — data loss risk"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  dimensions          = { DomainName = var.opensearch_domain_name, ClientId = data.aws_caller_identity.current.account_id }
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "opensearch_cluster_yellow" {
  count               = var.enable_opensearch_alarms ? 1 : 0
  alarm_name          = "${local.name}-opensearch-cluster-yellow"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ClusterStatus.yellow"
  namespace           = "AWS/ES"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "OpenSearch cluster status is YELLOW for 3+ minutes"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions          = { DomainName = var.opensearch_domain_name, ClientId = data.aws_caller_identity.current.account_id }
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "opensearch_free_storage" {
  count               = var.enable_opensearch_alarms ? 1 : 0
  alarm_name          = "${local.name}-opensearch-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/ES"
  period              = 300
  statistic           = "Minimum"
  threshold           = 20480
  alarm_description   = "OpenSearch free storage below 20 GB on at least one node"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions          = { DomainName = var.opensearch_domain_name, ClientId = data.aws_caller_identity.current.account_id }
  tags                = local.tags
}

