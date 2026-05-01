
output "db_endpoint"            { value = module.rds.db_endpoint }
output "db_host"                { value = module.rds.db_host }
output "db_port"                { value = module.rds.db_port }
output "db_name"                { value = module.rds.db_name }
output "db_identifier"          { value = module.rds.db_identifier }
output "proxy_endpoint"         { value = module.rds.proxy_endpoint }
output "master_user_secret_arn" { value = module.rds.master_user_secret_arn }
output "rds_security_group_id"  { value = module.rds.security_group_id }

output "redis_primary_endpoint"     { value = module.elasticache.primary_endpoint }
output "redis_reader_endpoint"      { value = module.elasticache.reader_endpoint }
output "redis_security_group_id"    { value = module.elasticache.security_group_id }
output "redis_replication_group_id" { value = module.elasticache.replication_group_id }

output "opensearch_endpoint" {
  value = var.enable_opensearch ? module.opensearch[0].endpoint : ""
}

output "opensearch_domain_name" {
  value = var.enable_opensearch ? module.opensearch[0].domain_name : ""
}

output "redis_secret_arn" {
  value = module.secrets.redis_secret_arn
}

output "opensearch_secret_arn" {
  value = module.secrets.opensearch_secret_arn
}

output "origin_verify_secret_arn" {
  value = module.secrets.origin_verify_secret_arn
}

output "sns_topic_arn"  { value = module.monitoring.sns_topic_arn }
output "sns_topic_name" { value = module.monitoring.sns_topic_name }
