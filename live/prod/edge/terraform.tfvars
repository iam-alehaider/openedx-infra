project     = "openedx"
environment = "prod"
region      = "us-east-1"

root_domain = "yourcompany.com"
lms_domain  = "learn.yourcompany.com"
cms_domain  = "studio.yourcompany.com"

# fill after deploying k8s ingress
alb_dns_name = "k8s-openedx-xxxx.us-east-1.elb.amazonaws.com"
alb_arn      = "arn:aws:elasticloadbalancing:us-east-1:123456789:loadbalancer/app/openedx-prod/xxxx"

# prod: full global distribution
price_class                      = "PriceClass_All"
waf_rate_limit                   = 2000
waf_api_rate_limit               = 200
login_rate_limit                 = 20
enable_bot_control               = true
enable_geo_restriction           = true
geo_blocked_country_codes        = ["KP", "IR", "CU", "SY"]
waf_body_size_restriction_action = "block"   # prod: enforce body size limits

# prod: full security enabled
enable_signed_media_urls = true
jwt_public_key_ssm_path  = "/openedx/prod/jwt/public-key"
jwt_public_keys_ssm_path = "" 
jwt_issuer               = "https://auth.yourcompany.com"
jwt_audience             = "openedx-api"

cf_log_retention_days     = 30
waf_s3_log_retention_days = 90

# prod: maintenance page failover active
# run maintenance module first, then paste outputs here
lms_failover_domain  = "openedx-prod-maintenance-page.s3-website-us-east-1.amazonaws.com"
lms_failover_zone_id = "Z3AQBSTGFYJSTF"
cms_failover_domain  = "openedx-prod-maintenance-page.s3-website-us-east-1.amazonaws.com"
cms_failover_zone_id = "Z3AQBSTGFYJSTF"

# fill from data layer output after apply
opensearch_endpoint    = "https://search-openedx-prod-xxxx.us-east-1.es.amazonaws.com"
opensearch_domain_name = "openedx-prod-search"

tags = {
  CostCenter = "engineering"
  Owner      = "platform-team"
}
