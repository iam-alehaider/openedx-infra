
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "openedx"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "At least 2 availability zones required for HA."
  }
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)

  validation {
    condition     = length(var.public_subnets) >= 2
    error_message = "At least 2 public subnets required."
  }
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)

  validation {
    condition     = length(var.private_subnets) >= 2
    error_message = "At least 2 private subnets required."
  }
}

variable "database_subnets" {
  description = "CIDR blocks for database subnets (one per AZ)"
  type        = list(string)

  validation {
    condition     = length(var.database_subnets) >= 2
    error_message = "At least 2 database subnets required for Multi-AZ RDS."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway (cost saving for non-prod)"
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "EKS cluster name — used for subnet discovery tagging"
  type        = string
}

variable "flow_log_retention_days" {
  description = "CloudWatch log retention for VPC flow logs (days). Use 7-14 for dev, 90+ for prod."
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.flow_log_retention_days)
    error_message = "flow_log_retention_days must be a valid CloudWatch retention value."
  }
}

variable "flow_log_traffic_type" {
  description = "VPC flow log traffic type. Use REJECT to reduce cost, ALL for full audit."
  type        = string
  default     = "REJECT"

  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.flow_log_traffic_type)
    error_message = "flow_log_traffic_type must be ALL, ACCEPT, or REJECT."
  }
}

variable "tags" {
  description = "Additional tags to merge"
  type        = map(string)
  default     = {}
}


variable "region" {
  description = "AWS region for VPC endpoint service names (e.g. us-east-1)"
  type        = string
}
