project     = "openedx"
environment = "dev"
region      = "us-east-1"

alarm_email = "dev-alerts@alecloud.site"

# RDS — dev: cheap, no HA, no protection
rds_instance_class               = "db.t3.micro"
rds_multi_az                     = false
rds_deletion_protection          = false
rds_backup_retention             = 1
rds_performance_insights_enabled = false
rds_proxy_role_arn               = ""    # fill after creating the IAM role

# Redis — dev: minimal
redis_node_type               = "cache.t3.micro"
redis_replica_count           = 1
redis_multi_az                = false
redis_deletion_protection     = false
redis_snapshot_retention_days = 1

# OpenSearch — too expensive in dev (~$200+/month for even smallest cluster)
enable_opensearch = false

# Fill after platform layer is applied:
redis_reader_role_arns      = []
opensearch_reader_role_arns = []

tags = {
  CostCenter = "engineering"
  Owner      = "platform-team"
}

rds_max_allocated_storage     = 50
opensearch_log_retention_days = 14   # opensearch disabled in dev anyway
