
variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project" {
  type        = string
  default     = "openedx"
  description = "Project name — used as the ECR repository name prefix (e.g. openedx/lms)"
}

variable "repositories" {
  type        = list(string)
  description = "List of ECR repo names to create under the project/ prefix"
  default     = ["lms", "cms", "mfe", "notes", "discovery", "forum"]

  validation {
    condition     = length(var.repositories) > 0
    error_message = "At least one repository must be specified."
  }
}

variable "image_retention_count" {
  type        = number
  default     = 30
  description = "Number of tagged images to keep per repository"

  validation {
    condition     = var.image_retention_count >= 5
    error_message = "image_retention_count must be at least 5."
  }
}

# FIX: Tag prefixes are now a variable — if CI changes tag format the lifecycle policy
# must be updated here, not discovered by surprise when images stop expiring
variable "image_tag_prefixes" {
  type        = list(string)
  description = "Tag prefixes matched by the lifecycle policy keep rule. Must match your CI tagging strategy."
  default     = ["v", "sha-", "release-"]
}

# FIX: Restrict pull access to specific role ARNs instead of entire AWS account root
variable "allowed_pull_role_arns" {
  type        = list(string)
  description = "IAM role ARNs allowed to pull images (e.g. EKS node role)"
  default     = []
}

# FIX: Restrict push access to specific role ARNs (e.g. GitHub Actions CI role)
variable "allowed_push_role_arns" {
  type        = list(string)
  description = "IAM role ARNs allowed to push images (e.g. GitHub Actions ECR push role)"
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

