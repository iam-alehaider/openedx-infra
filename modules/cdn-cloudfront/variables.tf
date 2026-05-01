


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

variable "alb_dns_name" {
  type        = string
  description = "DNS name of the ALB created by the AWS Load Balancer Controller ingress"
}

variable "s3_bucket_regional_domain" {
  type        = string
  description = "Regional domain name of the S3 bucket for static/media files"
}

variable "s3_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket (needed for signed URL KMS grants)"
}


variable "s3_bucket_id" {
  type        = string
  description = "Name (ID) of the S3 bucket for static/media files. Required for OAC bucket policy."
}


variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN (must be in us-east-1 for CloudFront)"
}

variable "origin_verify_secret" {
  type        = string
  sensitive   = true
  description = "Secret value sent in X-Origin-Verify header. Read from Secrets Manager at apply time."
}

variable "price_class" {
  type        = string
  default     = "PriceClass_100"
  description = "CloudFront price class. PriceClass_100 = US/EU only (cheapest)."

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "price_class must be PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "domain_aliases" {
  type        = list(string)
  description = "Custom domain names for the CloudFront distribution"
}

variable "waf_rate_limit" {
  type        = number
  default     = 2000
  description = "Maximum requests per 5-minute window per IP for general traffic before WAF blocks"

  validation {
    condition     = var.waf_rate_limit >= 100
    error_message = "waf_rate_limit must be at least 100."
  }
}

variable "waf_api_rate_limit" {
  type        = number
  default     = 200
  description = "Stricter rate limit for /api/* paths per IP per 5-minute window (P3)"

  validation {
    condition     = var.waf_api_rate_limit >= 50
    error_message = "waf_api_rate_limit must be at least 50."
  }
}

variable "waf_blocked_ip_cidrs" {
  type        = list(string)
  default     = []
  description = "List of IP CIDRs to explicitly block at the WAF layer"
}

variable "admin_allowed_ip_cidrs" {
  type        = list(string)
  default     = []
  description = "IP CIDRs allowed to access /admin/* paths. Empty = no IP restriction on admin (not recommended for prod). (P3)"
}


variable "cf_log_retention_days" {
  type        = number
  default     = 30
  description = "Days to retain CloudFront access logs in S3"
}

variable "waf_s3_log_retention_days" {
  type        = number
  default     = 90
  description = "Days to retain WAF logs in S3 (via Kinesis Firehose) for SIEM/OpenSearch ingestion (P1)"
}

variable "opensearch_endpoint" {
  type        = string
  default     = ""
  description = "Optional OpenSearch domain endpoint for WAF log SIEM delivery. Leave empty to skip. (P1)"
}

variable "jwt_public_key_ssm_path" {
  type        = string
  default     = ""
  description = "SSM Parameter Store path containing the JWT public key (PEM) for Lambda@Edge validation. Leave empty to skip JWT edge validation. (P2)"
}

variable "enable_bot_control" {
  type        = bool
  default     = true
  description = "Enable AWS Managed Rules Bot Control rule set (P1). Adds ~$10/month at COMMON inspection level."
}

variable "enable_geo_restriction" {
  type        = bool
  default     = false
  description = "Enable geo-restriction WAF rule to block high-risk country codes (P1)"
}

variable "geo_blocked_country_codes" {
  type        = list(string)
  default     = []
  description = "ISO 3166-1 alpha-2 country codes to block when enable_geo_restriction = true. e.g. [\"KP\", \"IR\", \"CU\"]"
}

variable "enable_signed_media_urls" {
  type        = bool
  default     = true
  description = "Require CloudFront signed URLs/cookies for /media/* paths (P2)"
}

variable "tags" {
  type    = map(string)
  default = {}
}



variable "opensearch_domain_name" {
  type        = string
  default     = ""
  description = "OpenSearch domain name (not the endpoint URL). Required when opensearch_endpoint is set."
}


variable "jwt_issuer" {
  type        = string
  default     = ""
  description = "Expected JWT issuer (iss claim). e.g. https://auth.example.com"
}

variable "jwt_audience" {
  type        = string
  default     = ""
  description = "Expected JWT audience (aud claim). e.g. openedx-api"
}

variable "jwt_public_keys_ssm_path" {
  type        = string
  default     = ""
  description = "SSM path to JSON object mapping kid → PEM, for multi-key rotation. Alternative to jwt_public_key_ssm_path."
}


variable "alb_arn" {
  type        = string
  description = "ARN of the ALB to attach regional WAF. Leave empty on first apply before k8s ingress is deployed."

  validation {
    condition     = var.alb_arn == "" || can(regex("^arn:aws:elasticloadbalancing:", var.alb_arn))
    error_message = "alb_arn must be a valid ELB ARN or empty string."
  }
}



variable "login_rate_limit" {
  type        = number
  default     = 20
  description = "Login attempts per 5-minute window per IP before CAPTCHA challenge (P3)"

  validation {
    condition     = var.login_rate_limit >= 10
    error_message = "login_rate_limit must be at least 10."
  }
}



variable "waf_body_size_restriction_action" {
  type        = string
  default     = "count"
  description = "Action for SizeRestrictions_BODY WAF rule. Use 'count' in staging to review false positives, 'block' in prod once confirmed safe."

  validation {
    condition     = contains(["count", "block"], var.waf_body_size_restriction_action)
    error_message = "Must be 'count' or 'block'."
  }
}



variable "alarm_sns_topic_arn" {
  type        = string
  default     = ""
  description = "SNS topic ARN to notify when WAF CloudWatch alarms fire. Leave empty to skip notifications."
}




