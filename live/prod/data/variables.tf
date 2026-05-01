variable "project" {
  type    = string
  default = "openedx"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "alarm_email" {
  type = string
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "rds_multi_az" {
  type    = bool
  default = false
}

variable "rds_deletion_protection" {
  type    = bool
  default = true
}

variable "rds_backup_retention" {
  type    = number
  default = 7
}

variable "rds_performance_insights_enabled" {
  type    = bool
  default = false
}

variable "rds_proxy_role_arn" {
  type        = string
  description = "IAM role ARN for RDS Proxy. Created manually or in a separate layer."
}

variable "redis_node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "redis_replica_count" {
  type    = number
  default = 1
}

variable "redis_multi_az" {
  type    = bool
  default = false
}

variable "redis_deletion_protection" {
  type    = bool
  default = true
}

variable "redis_snapshot_retention_days" {
  type    = number
  default = 1
}

variable "enable_opensearch" {
  type    = bool
  default = false
}

variable "opensearch_instance_type" {
  type    = string
  default = "t3.small.search"
}

variable "opensearch_instance_count" {
  type    = number
  default = 1
}

variable "opensearch_volume_size_gb" {
  type    = number
  default = 20
}

variable "redis_reader_role_arns" {
  type    = list(string)
  default = []
}

variable "opensearch_reader_role_arns" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "rds_max_allocated_storage" {
  type        = number
  default     = 50
  description = "Maximum autoscaling ceiling for RDS storage in GB."

  validation {
    condition     = var.rds_max_allocated_storage >= 20
    error_message = "rds_max_allocated_storage must be at least 20 GB."
  }
}

variable "opensearch_log_retention_days" {
  type        = number
  default     = 14
  description = "Days to retain OpenSearch logs in CloudWatch."

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 180, 365], var.opensearch_log_retention_days)
    error_message = "Must be a valid CloudWatch retention value."
  }
}
