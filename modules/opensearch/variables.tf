
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
  description = "VPC CIDR — used to restrict OpenSearch security group egress"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for OpenSearch. Must have at least as many subnets as instance_count (up to 3)."

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least one subnet ID required."
  }
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security groups allowed to access OpenSearch (EKS node SG)"
}

variable "engine_version" {
  type        = string
  default     = "OpenSearch_2.11"
  description = "OpenSearch engine version string (e.g. OpenSearch_2.11)"
}

variable "instance_type" {
  type    = string
  default = "m5.large.search"

  validation {
    condition     = can(regex("\\.search$", var.instance_type))
    error_message = "instance_type must end with .search (e.g. m5.large.search)."
  }
}

variable "instance_count" {
  type    = number
  default = 3

  validation {
    condition     = var.instance_count >= 1
    error_message = "instance_count must be at least 1."
  }
}

variable "master_instance_type" {
  type    = string
  default = "m5.large.search"
}

variable "volume_size_gb" {
  type    = number
  default = 100

  validation {
    condition     = var.volume_size_gb >= 10
    error_message = "volume_size_gb must be at least 10."
  }
}

variable "master_user" {
  type    = string
  default = "admin"
}

# FIX: Accept secret ARN instead of plaintext password
# The password is read from Secrets Manager at apply time — never stored in Terraform state
variable "master_password_secret_arn" {
  type        = string
  description = "ARN of the Secrets Manager secret containing the OpenSearch master password. Use module.secrets.opensearch_secret_arn."
}

variable "create_service_linked_role" {
  type    = bool
  default = false
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "log_retention_days" {
  type        = number
  default     = 30
  description = "Days to retain OpenSearch logs in CloudWatch. Use 90+ for prod."

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 180, 365], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch retention value."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

