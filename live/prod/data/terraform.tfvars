project     = "openedx"
environment = "prod"
region      = "us-east-1"

alarm_email = "prod-alerts@alecloud.site"

# prod: HA database with deletion protection
rds_instance_class               = "db.t3.large"
rds_multi_az                     = true
rds_deletion_protection          = true
rds_backup_retention             = 7
rds_performance_insights_enabled = true
rds_proxy_role_arn               = ""  

# prod: HA Redis with Multi-AZ
redis_node_type               = "cache.r6g.large"
redis_replica_count           = 2
redis_multi_az                = true
redis_deletion_protection     = true
redis_snapshot_retention_days = 7

# prod: OpenSearch enabled
enable_opensearch         = true
opensearch_instance_type  = "m5.large.search"
opensearch_instance_count = 3
opensearch_volume_size_gb = 100

# fill after platform layer applied
redis_reader_role_arns = [
  "arn:aws:iam::119778517587:role/openedx-prod-openedx-s3-role"
]
opensearch_reader_role_arns = [
  "arn:aws:iam::119778517587:role/openedx-prod-openedx-s3-role"
]

tags = {
  CostCenter = "engineering"
  Owner      = "platform-team"
}

rds_max_allocated_storage     = 500
opensearch_log_retention_days = 90
