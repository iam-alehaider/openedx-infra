project     = "openedx"
environment = "dev"
region      = "us-east-1"

root_domain = "yourcompany.com"
lms_domain  = "dev.learn.yourcompany.com"
cms_domain  = "dev.studio.yourcompany.com"

# Fill after deploying Kubernetes ingress — ALB is created by k8s controller
alb_dns_name = ""
alb_arn      = ""

# DEV: cheapest CloudFront config
price_class                      = "PriceClass_100"
waf_rate_limit                   = 500
waf_api_rate_limit               = 100
login_rate_limit                 = 20
enable_bot_control               = false   # saves $10/month in dev
enable_geo_restriction           = false
geo_blocked_country_codes        = []
waf_body_size_restriction_action = "count" # never block in dev

# DEV: easier testing — no signed URLs, no JWT at edge
enable_signed_media_urls = false
jwt_public_key_ssm_path  = ""
jwt_public_keys_ssm_path = ""
jwt_issuer               = ""
jwt_audience             = ""

cf_log_retention_days     = 7
waf_s3_log_retention_days = 14

# DEV: no failover — no maintenance page
lms_failover_domain  = ""
lms_failover_zone_id = ""
cms_failover_domain  = ""
cms_failover_zone_id = ""

# DEV: no OpenSearch
opensearch_endpoint    = ""
opensearch_domain_name = ""

tags = {
  CostCenter = "engineering"
  Owner      = "platform-team"
}
