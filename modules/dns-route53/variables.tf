
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

variable "lms_domain" {
  type        = string
  description = "Full LMS domain (e.g. learn.example.com)"
}

variable "cms_domain" {
  type        = string
  description = "Full CMS/Studio domain (e.g. studio.example.com)"
}

# FIX: Explicit root_domain replaces the fragile split/join parsing that breaks on .co.uk etc.
variable "root_domain" {
  type        = string
  description = "Root hosted zone domain (e.g. example.com). Must match an existing Route53 hosted zone."
}

variable "cloudfront_domain" {
  type        = string
  description = "CloudFront distribution domain name"
}

variable "cloudfront_zone_id" {
  type        = string
  description = "CloudFront hosted zone ID (always Z2FDTNDATAQYW2 for AWS)"
  default     = "Z2FDTNDATAQYW2"
}

# FIX: Failover routing — secondary record activated when primary health check fails
variable "lms_failover_domain" {
  type        = string
  description = "Failover origin domain for LMS (e.g. maintenance page ALB DNS). Leave empty to skip secondary record."
  default     = ""
}

variable "lms_failover_zone_id" {
  type        = string
  description = "Hosted zone ID for the LMS failover alias target"
  default     = ""
}

variable "cms_failover_domain" {
  type        = string
  description = "Failover origin domain for CMS. Leave empty to skip secondary record."
  default     = ""
}

variable "cms_failover_zone_id" {
  type        = string
  description = "Hosted zone ID for the CMS failover alias target"
  default     = ""
}

variable "query_log_retention_days" {
  type        = number
  default     = 30
  description = "Days to retain Route53 query logs in CloudWatch"
}

variable "tags" {
  type    = map(string)
  default = {}
}

