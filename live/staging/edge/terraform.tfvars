
# live/staging/edge/terraform.tfvars
# FIXED: added jwt_public_keys_ssm_path (was declared in variables.tf but absent here)

project     = "openedx"
environment = "staging"
region      = "us-east-1"

root_domain = "alecloud.site"
lms_domain  = "staging.learn.alecloud.site"
cms_domain  = "staging.studio.alecloud.site"

alb_dns_name = ""    # fill after deploying k8s ingress
alb_arn      = ""

price_class                      = "PriceClass_100"
waf_rate_limit                   = 1000
waf_api_rate_limit               = 150
login_rate_limit                 = 20
enable_bot_control               = true
enable_geo_restriction           = false
geo_blocked_country_codes        = []
waf_body_size_restriction_action = "count"

enable_signed_media_urls = true
jwt_public_key_ssm_path  = "/openedx/staging/jwt/public-key"
# FIX: this variable was declared in variables.tf but missing from tfvars
jwt_public_keys_ssm_path = ""    # leave empty; use single key path above
jwt_issuer               = "https://auth-staging.alecloud.site"
jwt_audience             = "openedx-api"

cf_log_retention_days     = 14
waf_s3_log_retention_days = 30

# Fill from account-wide/maintenance outputs after running that layer
lms_failover_domain  = "openedx-prod-maintenance-page.s3-website-us-east-1.amazonaws.com"
lms_failover_zone_id = "Z3AQBSTGFYJSTF"
cms_failover_domain  = "openedx-prod-maintenance-page.s3-website-us-east-1.amazonaws.com"
cms_failover_zone_id = "Z3AQBSTGFYJSTF"

# Fill from data layer outputs after apply
opensearch_endpoint    = ""
opensearch_domain_name = ""

tags = {
  CostCenter = "engineering"
  Owner      = "platform-team"
}

