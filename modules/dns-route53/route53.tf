

#=======================================================================
# LMS PRIMARY DNS Record
#
# Always points to CloudFront.
# health_check_id is only attached when failover is configured.
# Without a secondary record, attaching a health check does nothing
# useful — Route53 would mark primary unhealthy but have nowhere
# to route traffic.
#
# CURRENT STATE: health_check_id = null (no check attached)
# AFTER SETTING lms_failover_domain: health check attaches automatically
#=======================================================================
resource "aws_route53_record" "lms_primary" {
  zone_id        = data.aws_route53_zone.main.zone_id
  name           = var.lms_domain
  type           = "A"
  set_identifier = "lms-primary"

  alias {
    name                   = var.cloudfront_domain
    zone_id                = var.cloudfront_zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "PRIMARY"
  }

  # Only attach health check when secondary failover record exists.
  # When lms_failover_domain = "" → null (no health check attached)
  # When lms_failover_domain is set → health check drives failover
  health_check_id = var.lms_failover_domain != "" ? aws_route53_health_check.lms[0].id : null
}

#=======================================================================
# LMS SECONDARY DNS Record (Maintenance Page Failover)
#
# CURRENT STATE: count=0 — not created because lms_failover_domain=""
#
# TO ACTIVATE (Option B — S3 maintenance page):
#   In your tfvars set:
#     lms_failover_domain  = "openedx-prod-maintenance-page.s3-website-us-east-1.amazonaws.com"
#     lms_failover_zone_id = "Z3AQBSTGFYJSTF"
#
# What happens when activated:
#   - Health check polls learn.example.com/heartbeat every 30 seconds
#   - After 3 failures (90 sec) Route53 marks PRIMARY unhealthy
#   - Route53 automatically serves this SECONDARY record
#   - Users see maintenance page instead of DNS error
#   - When ALB recovers, health check passes and PRIMARY is restored
#   - No manual intervention needed
#
# IMPORTANT: lms_failover_zone_id values by region:
#   us-east-1 S3 website: Z3AQBSTGFYJSTF
#   us-west-2 S3 website: Z3BJ6K6RIION7M
#   eu-west-1 S3 website: Z1BKCTXD74EZPE
#   (full list: https://docs.aws.amazon.com/general/latest/gr/s3.html)
#=======================================================================
resource "aws_route53_record" "lms_secondary" {
  count          = var.lms_failover_domain != "" ? 1 : 0
  zone_id        = data.aws_route53_zone.main.zone_id
  name           = var.lms_domain
  type           = "A"
  set_identifier = "lms-secondary"

  alias {
    name                   = var.lms_failover_domain
    zone_id                = var.lms_failover_zone_id
    evaluate_target_health = false
  }

  failover_routing_policy {
    type = "SECONDARY"
  }
}

#=======================================================================
# CMS PRIMARY DNS Record
#
# Same logic as LMS primary above.
#=======================================================================
resource "aws_route53_record" "cms_primary" {
  zone_id        = data.aws_route53_zone.main.zone_id
  name           = var.cms_domain
  type           = "A"
  set_identifier = "cms-primary"

  alias {
    name                   = var.cloudfront_domain
    zone_id                = var.cloudfront_zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = var.cms_failover_domain != "" ? aws_route53_health_check.cms[0].id : null
}

#=======================================================================
# CMS SECONDARY DNS Record (Maintenance Page Failover)
#
# CURRENT STATE: count=0 — not created because cms_failover_domain=""
#
# TO ACTIVATE: Set cms_failover_domain and cms_failover_zone_id
# in tfvars — same values as LMS if using the same maintenance page.
#=======================================================================
resource "aws_route53_record" "cms_secondary" {
  count          = var.cms_failover_domain != "" ? 1 : 0
  zone_id        = data.aws_route53_zone.main.zone_id
  name           = var.cms_domain
  type           = "A"
  set_identifier = "cms-secondary"

  alias {
    name                   = var.cms_failover_domain
    zone_id                = var.cms_failover_zone_id
    evaluate_target_health = false
  }

  failover_routing_policy {
    type = "SECONDARY"
  }
}


