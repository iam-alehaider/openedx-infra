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



# IAM roles that are allowed to read the Redis secret (e.g. EKS IRSA role ARNs)

variable "redis_reader_role_arns" {
  type        = list(string)
  description = "IAM role ARNs allowed to read the Redis secret. Must be set before applying to production. Defaults to empty — apply with caution in dev only."
  default     = []

  validation {
    condition     = alltrue([for arn in var.redis_reader_role_arns : can(regex("^arn:aws:iam::[0-9]{12}:role/.+", arn))])
    error_message = "All redis_reader_role_arns must be valid IAM role ARNs."
  }
}




# IAM roles that are allowed to read the OpenSearch secret

variable "opensearch_reader_role_arns" {
  type        = list(string)
  description = "IAM role ARNs allowed to read the OpenSearch secret."
  default     = []

  validation {
    condition     = alltrue([for arn in var.opensearch_reader_role_arns : can(regex("^arn:aws:iam::[0-9]{12}:role/.+", arn))])
    error_message = "All opensearch_reader_role_arns must be valid IAM role ARNs."
  }
}



