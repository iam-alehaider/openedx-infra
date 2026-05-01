

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

variable "github_org" {
  type        = string
  description = "GitHub organization or user name (e.g. my-org)"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name (e.g. openedx-eks-infra)"
}

variable "github_main_branch" {
  type        = string
  description = "Branch that the ECR push role trusts (e.g. main)"
  default     = "main"
}

variable "eks_cluster_name" {
  type        = string
  description = "EKS cluster name — used to scope the deploy role to a specific cluster ARN"
}

variable "ecr_repository_names" {
  type        = list(string)
  description = "ECR repository names the CI role is allowed to push to (without the project/ prefix)"
  default     = ["lms", "cms", "mfe", "notes", "discovery", "forum"]
}

variable "tags" {
  type    = map(string)
  default = {}
}

