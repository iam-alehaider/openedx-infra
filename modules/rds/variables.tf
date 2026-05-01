

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"

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
  type        = string
  description = "VPC ID where RDS will be deployed"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR — used to restrict RDS security group egress"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Database subnet IDs for RDS (isolated subnets, no internet route)"
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security group IDs allowed to connect to RDS (e.g. EKS node SG)"
}

variable "engine_version" {
  type    = string
  default = "8.0.35"
}

variable "db_name" {
  type    = string
  default = "openedx"
}

variable "db_username" {
  type    = string
  default = "openedx_admin"
}

variable "instance_class" {
  type        = string
  default     = "db.t3.micro"
  description = "RDS instance class. Use db.t3.micro for dev, db.t3.large+ for prod."

  validation {
    condition     = can(regex("^db\\.", var.instance_class))
    error_message = "instance_class must start with 'db.' (e.g. db.t3.micro)."
  }
}

variable "allocated_storage" {
  type        = number
  description = "Initial storage size in GB"
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "Minimum allocated_storage is 20 GB."
  }
}

variable "max_allocated_storage" {
  type        = number
  description = "Maximum storage autoscaling ceiling in GB"
  default     = 100

  validation {
    condition     = var.max_allocated_storage >= var.allocated_storage
    error_message = "max_allocated_storage must be >= allocated_storage."
  }
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ. Set false in dev to halve costs."
  default     = false
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "backup_retention" {
  type        = number
  description = "Days to retain automated backups. Use 1 for dev, 7+ for prod."
  default     = 7

  validation {
    condition     = var.backup_retention >= 1 && var.backup_retention <= 35
    error_message = "backup_retention must be between 1 and 35."
  }
}

variable "backup_window" {
  type        = string
  description = "Preferred backup window (UTC). Must not overlap maintenance_window."
  default     = "02:00-03:00"
}

variable "maintenance_window" {
  type        = string
  description = "Preferred maintenance window (UTC)."
  default     = "sun:04:00-sun:05:00"
}

variable "cloudwatch_log_exports" {
  type        = list(string)
  description = "Log types to export. Omit 'general' in prod — it is very expensive and noisy."
  default     = ["error", "slowquery"]

  validation {
    condition     = alltrue([for l in var.cloudwatch_log_exports : contains(["error", "general", "slowquery", "audit"], l)])
    error_message = "Valid log exports are: error, general, slowquery, audit."
  }
}

variable "performance_insights_enabled" {
  type    = bool
  default = true
}

variable "performance_insights_retention_days" {
  type        = number
  description = "Days to retain Performance Insights data. 7 = free tier."
  default     = 7

  validation {
    condition     = contains([7, 31, 62, 93, 124, 155, 186, 217, 248, 279, 310, 341, 372, 403, 434, 465, 496, 527, 731], var.performance_insights_retention_days)
    error_message = "performance_insights_retention_days must be 7 or a multiple of 31 up to 731."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}



variable "proxy_role_arn" {
  type        = string
  description = "IAM role ARN for RDS Proxy to access Secrets Manager. Create this role outside the module and pass it in."

  validation {
    condition     = var.proxy_role_arn == "" || can(regex("^arn:aws:iam::[0-9]{12}:role/.+", var.proxy_role_arn))
    error_message = "proxy_role_arn must be a valid IAM role ARN (arn:aws:iam::ACCOUNT:role/NAME) or empty string to skip proxy creation."
  }
}


