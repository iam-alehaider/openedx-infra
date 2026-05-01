

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string

  validation {
    condition     = can(regex("^1\\.(2[7-9]|[3-9][0-9])$", var.cluster_version))
    error_message = "cluster_version must be a supported Kubernetes version (e.g. 1.29)."
  }
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block — used to restrict node egress within VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for EKS cluster endpoint"
  type        = list(string)
}

variable "node_groups" {
  description = "Map of managed node group configs"
  type = map(object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    capacity_type  = string
    disk_size_gb   = number
    labels         = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint. Set false in prod."
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_cidrs" {
  description = "CIDRs allowed to access public API endpoint (office/VPN IPs only)"
  type        = list(string)
  default     = []
}

variable "cluster_log_types" {
  description = "EKS control plane log types to enable. Reduce in dev to cut costs."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "CloudWatch log retention for EKS control plane logs (days)"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365], var.cluster_log_retention_days)
    error_message = "Must be a valid CloudWatch retention period."
  }
}

variable "addon_versions" {
  description = "Map of EKS addon versions to pin. Expose as variables for easier upgrades."
  type        = map(string)
  default = {
    kube_proxy = "v1.29.3-eksbuild.2"
    vpc_cni    = "v1.18.1-eksbuild.3"
    coredns    = "v1.11.1-eksbuild.9"
    ebs_csi    = "v1.30.0-eksbuild.1"
    efs_csi    = "v2.0.7-eksbuild.1"
  }
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

