variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project" {
  type    = string
  default = "openedx"
}

variable "alarm_email" {
  type        = string
  description = "Email address for CloudWatch alarm notifications"
}

# FIX: These must now come from module outputs, not hardcoded strings
# In environments/prod/main.tf wire as: rds_identifier = module.rds.db_identifier

variable "rds_identifier" {
  type        = string
  description = "RDS DB instance identifier — use module.rds.db_identifier output"
}

variable "redis_replication_id" {
  type        = string
  description = "ElastiCache replication group ID — use module.elasticache.replication_group_id output"
}

variable "opensearch_domain_name" {
  type        = string
  description = "OpenSearch domain name — use module.opensearch.domain_name output when enabled"
  default     = ""
}

variable "enable_opensearch_alarms" {
  type        = bool
  default     = false
  description = "Set true only when the opensearch module is enabled and domain_name is provided"
}

variable "tags" {
  type    = map(string)
  default = {}
}

