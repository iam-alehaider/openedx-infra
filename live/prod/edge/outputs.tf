output "distribution_id"     { value = module.cdn.distribution_id }
output "distribution_domain" { value = module.cdn.distribution_domain }
output "distribution_arn"    { value = module.cdn.distribution_arn }
output "waf_arn"             { value = module.cdn.waf_arn }

output "certificate_arn" { value = aws_acm_certificate_validation.main.certificate_arn }

output "route53_zone_id"     { value = module.dns.route53_zone_id }
output "lms_failover_configured" { value = module.dns.lms_failover_configured }
output "cf_log_bucket_name"  { value = module.cdn.cf_log_bucket_name }
output "waf_log_bucket_name" { value = module.cdn.waf_log_bucket_name }
