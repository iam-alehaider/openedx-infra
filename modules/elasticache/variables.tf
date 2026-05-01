

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

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR — used to restrict Redis security group egress"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for Redis"
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security group IDs allowed to access Redis"
}

variable "node_type" {
  type        = string
  default     = "cache.t3.micro"
  description = "ElastiCache node type. Use cache.t3.micro for dev, cache.r6g.large+ for prod."

  validation {
    condition     = can(regex("^cache\\.", var.node_type))
    error_message = "node_type must start with 'cache.' (e.g. cache.t3.micro)."
  }
}

variable "engine_version" {
  type        = string
  default     = "7.0"
  description = "Redis engine version."
}

variable "replica_count" {
  type        = number
  default     = 1
  description = "Number of read replicas. Use 1 for dev (HA), 2-3 for prod."

  validation {
    condition     = var.replica_count >= 1
    error_message = "At least 1 replica required for HA."
  }
}

variable "multi_az_enabled" {
  type        = bool
  default     = true
  description = "Enable Multi-AZ. Set false in dev to reduce costs."
}


variable "snapshot_retention_days" {
  type        = number
  default     = 7
  description = "Days to retain Redis snapshots. Use 1-3 for dev, 7-14 for prod."

  validation {
    condition     = var.snapshot_retention_days >= 1 && var.snapshot_retention_days <= 35
    error_message = "snapshot_retention_days must be between 1 and 35."
  }
}

variable "snapshot_window" {
  type        = string
  default     = "02:00-03:00"
  description = "Daily time range for Redis snapshots (UTC)."
}

variable "maintenance_window" {
  type        = string
  default     = "sun:04:00-sun:05:00"
  description = "Weekly maintenance window (UTC)."
}

variable "log_retention_days" {
  type        = number
  default     = 14
  description = "CloudWatch log retention for Redis slow logs. Use 7+ for prod."

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch retention value."
  }
}

variable "apply_immediately" {
  type    = bool
  default = false
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}


variable "redis_secret_arn" {
  type        = string
  description = "ARN of the Secrets Manager secret containing Redis auth credentials. Created outside this module and passed in."
}
