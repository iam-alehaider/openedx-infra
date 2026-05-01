

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${local.name}-redis"
  description          = "Redis for ${local.name} OpenEdX"

  engine        = "redis"
  engine_version = var.engine_version
  node_type     = var.node_type
  port          = 6379

  num_node_groups         = 1
  replicas_per_node_group = var.replica_count
  apply_immediately       = var.apply_immediately

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  parameter_group_name = aws_elasticache_parameter_group.redis.name

  at_rest_encryption_enabled = true
  # FIX: Use customer-managed KMS key (was using AWS default key)
  kms_key_id                 = aws_kms_key.redis.arn
  transit_encryption_enabled = true
  auth_token = data.aws_secretsmanager_secret_version.redis.secret_string
  
  automatic_failover_enabled = true
  multi_az_enabled           = var.multi_az_enabled

  # FIX: snapshot_retention_limit is now a variable (was hardcoded 3 — too low for prod)
  snapshot_retention_limit = var.snapshot_retention_days
  snapshot_window          = var.snapshot_window
  maintenance_window       = var.maintenance_window

  deletion_protection        = var.deletion_protection
  auto_minor_version_upgrade = true


  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "engine-log"
  }

  tags = merge(local.tags, { Name = "${local.name}-redis" })
}



