project     = "openedx"
environment = "staging"
region      = "us-east-1"

alarm_email = "staging-alerts@yourcompany.com"

rds_instance_class               = "db.t3.small"
rds_multi_az                     = false
rds_deletion_protection          = true
rds_backup_retention             = 3
rds_performance_insights_enabled = true
rds_proxy_role_arn               = ""

redis_node_type               = "cache.t3.small"
redis_replica_count           = 1
redis_multi_az                = false
redis_deletion_protection     = true
redis_snapshot_retention_days = 3

# staging: enable OpenSearch to test search functionality
enable_opensearch         = true
opensearch_instance_type  = "t3.small.search"
opensearch_instance_count = 1
opensearch_volume_size_gb = 20

redis_reader_role_arns      = []
opensearch_reader_role_arns = []

tags = {
  CostCenter = "engineering"
  Owner      = "platform-team"
}

rds_max_allocated_storage     = 100
opensearch_log_retention_days = 14
