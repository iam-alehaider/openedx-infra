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

variable "cluster_version" {
  type = string
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "node_desired_size" {
  type    = number
  default = 1
}

variable "cluster_endpoint_public_access" {
  type    = bool
  default = false
}

variable "developer_cidrs" {
  type    = list(string)
  default = []
}

variable "cluster_log_types" {
  type    = list(string)
  default = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  type    = number
  default = 30
}

variable "efs_throughput_mode" {
  type    = string
  default = "elastic"
}

variable "addon_versions" {
  type = map(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}


variable "node_disk_size_gb" {
  type        = number
  default     = 20
  description = "EBS disk size in GB for EKS nodes. Use 20 for dev, 30 for staging, 50 for prod."

  validation {
    condition     = var.node_disk_size_gb >= 20
    error_message = "node_disk_size_gb must be at least 20."
  }
}
