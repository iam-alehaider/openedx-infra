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

variable "root_domain" {
  type = string
}

variable "lms_domain" {
  type = string
}

variable "cms_domain" {
  type = string
}



variable "alb_dns_name" {
  type        = string
  description = "ALB DNS name created by AWS Load Balancer Controller after EKS ingress is deployed"

  validation {
    condition     = var.alb_dns_name == "" || can(regex("^[a-z0-9][a-z0-9.-]+\\.elb\\.amazonaws\\.com$", var.alb_dns_name))
    error_message = "alb_dns_name must be a valid ELB DNS name (e.g. k8s-openedx-xxx.us-east-1.elb.amazonaws.com) or empty string."
  }
}


variable "alb_arn" {
  type        = string
  description = "ALB ARN — needed to attach the regional WAF"

  validation {
    condition     = var.alb_arn == "" || can(regex("^arn:aws:elasticloadbalancing:", var.alb_arn))
    error_message = "alb_arn must be a valid ELB ARN or empty string."
  }
}


variable "price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "waf_rate_limit" {
  type    = number
  default = 2000
}

variable "waf_api_rate_limit" {
  type    = number
  default = 200
}

variable "login_rate_limit" {
  type    = number
  default = 20
}

variable "enable_bot_control" {
  type    = bool
  default = true
}

variable "enable_geo_restriction" {
  type    = bool
  default = false
}

variable "geo_blocked_country_codes" {
  type    = list(string)
  default = []
}

variable "waf_body_size_restriction_action" {
  type    = string
  default = "count"
}

variable "enable_signed_media_urls" {
  type    = bool
  default = true
}

variable "jwt_public_key_ssm_path" {
  type    = string
  default = ""
}

variable "jwt_public_keys_ssm_path" {
  type    = string
  default = ""
}

variable "jwt_issuer" {
  type    = string
  default = ""
}

variable "jwt_audience" {
  type    = string
  default = ""
}

variable "cf_log_retention_days" {
  type    = number
  default = 30
}

variable "waf_s3_log_retention_days" {
  type    = number
  default = 90
}

variable "opensearch_endpoint" {
  type    = string
  default = ""
}

variable "opensearch_domain_name" {
  type    = string
  default = ""
}

variable "lms_failover_domain" {
  type    = string
  default = ""
}

variable "lms_failover_zone_id" {
  type    = string
  default = ""
}

variable "cms_failover_domain" {
  type    = string
  default = ""
}

variable "cms_failover_zone_id" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}


