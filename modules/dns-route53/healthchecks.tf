
#=======================================================================
# Health Check for LMS
#
# CURRENT STATE: Only created when lms_failover_domain is set.
# Without a secondary record, a health check costs ~$0.50/month
# and has nothing to fail over to — so we skip it until failover
# is configured.
#
# TO ACTIVATE: Set lms_failover_domain in tfvars — health check
# is created automatically on next terraform apply.
#=======================================================================
resource "aws_route53_health_check" "lms" {
  count = var.lms_failover_domain != "" ? 1 : 0

  fqdn              = var.lms_domain
  port              = 443
  type              = "HTTPS"
  resource_path     = "/heartbeat"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(local.tags, { Name = "${local.name}-lms-health" })
}

#=======================================================================
# Health Check for CMS
#
# Same logic as LMS above — only created when failover is configured.
#=======================================================================
resource "aws_route53_health_check" "cms" {
  count = var.cms_failover_domain != "" ? 1 : 0

  fqdn              = var.cms_domain
  port              = 443
  type              = "HTTPS"
  resource_path     = "/heartbeat"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(local.tags, { Name = "${local.name}-cms-health" })
}
