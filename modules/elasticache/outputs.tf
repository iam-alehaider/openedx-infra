
output "primary_endpoint" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "reader_endpoint" {
  value = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "port" {
  value = aws_elasticache_replication_group.redis.port
}

output "security_group_id" {
  value = aws_security_group.redis.id
}

output "replication_group_id" {
  description = "The ID of the Redis replication group — use this in the monitoring module"
  value       = aws_elasticache_replication_group.redis.replication_group_id
}

output "kms_key_arn" {
  value = aws_kms_key.redis.arn
}

