
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
  description = "VPC CIDR — used to restrict EFS security group egress"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets to place EFS mount targets in (one per AZ)"
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security groups allowed to mount EFS (EKS node SG)"
}

variable "throughput_mode" {
  type        = string
  default     = "elastic"
  description = "EFS throughput mode. Use 'elastic' for prod (steady workloads), 'bursting' for dev."

  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "throughput_mode must be bursting, provisioned, or elastic."
  }
}

variable "transition_to_ia" {
  type        = string
  default     = "AFTER_30_DAYS"
  description = "When to transition files to Infrequent Access storage class."

  validation {
    condition     = contains(["AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", "AFTER_90_DAYS"], var.transition_to_ia)
    error_message = "transition_to_ia must be one of: AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS."
  }
}

# FIX: Parameterized UID/GID to match Kubernetes pod security context
variable "openedx_uid" {
  type        = number
  default     = 1000
  description = "UID for the OpenEdX EFS access point. Must match the container user ID."
}

variable "openedx_gid" {
  type        = number
  default     = 1000
  description = "GID for the OpenEdX EFS access point. Must match the container group ID."
}

variable "access_point_permissions" {
  type        = string
  default     = "755"
  description = "POSIX permissions for the EFS access point root directory."
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "allowed_role_arns" {
  type = list(string)
}


