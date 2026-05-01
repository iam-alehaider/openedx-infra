

output "certificate_arn" {
  value = aws_acm_certificate_validation.main.certificate_arn
}

output "certificate_domain" {
  value = aws_acm_certificate.main.domain_name
}

output "route53_zone_id" {
  value = data.aws_route53_zone.main.zone_id
}

# null when failover not configured, health check ID when configured
output "lms_health_check_id" {
  value = var.lms_failover_domain != "" ? aws_route53_health_check.lms[0].id : null
}

output "cms_health_check_id" {
  value = var.cms_failover_domain != "" ? aws_route53_health_check.cms[0].id : null
}

# Expose failover status so parent module knows what is active
output "lms_failover_configured" {
  value       = var.lms_failover_domain != ""
  description = "True when LMS maintenance page failover is active"
}

output "cms_failover_configured" {
  value       = var.cms_failover_domain != ""
  description = "True when CMS maintenance page failover is active"
}

output "maintenance_page_note" {
  value = var.lms_failover_domain != "" ? (
    "Failover active → ${var.lms_failover_domain}"
  ) : "Failover not configured — set lms_failover_domain to activate"
}
