

output "distribution_id"           { value = aws_cloudfront_distribution.main.id }
output "distribution_domain"       { value = aws_cloudfront_distribution.main.domain_name }
output "distribution_arn"          { value = aws_cloudfront_distribution.main.arn }
output "waf_arn"                   { value = aws_wafv2_web_acl.cloudfront.arn }
output "cf_log_bucket_name"        { value = aws_s3_bucket.cf_logs.id }

# P1 outputs
output "waf_log_bucket_name"       { value = aws_s3_bucket.waf_logs.id }
output "waf_firehose_arn"          { value = aws_kinesis_firehose_delivery_stream.waf.arn }

# P2 outputs (null when features are disabled)
output "edge_jwt_lambda_arn" {
  value = local.enable_jwt_edge ? aws_lambda_function.edge_jwt[0].qualified_arn : null
}
output "media_signing_key_group_id" {
  value = var.enable_signed_media_urls ? aws_cloudfront_key_group.media_signing[0].id : null
}
output "media_signing_public_key_id" {
  value = var.enable_signed_media_urls ? aws_cloudfront_public_key.media_signing[0].id : null
}

# P3 outputs
output "admin_ip_set_arn" {
  value = local.enable_admin_ip_allowlist ? aws_wafv2_ip_set.admin_allowed[0].arn : null
}


output "response_headers_policy_id" {
  value = aws_cloudfront_response_headers_policy.security.id
}


output "alb_waf_arn" {
  value = aws_wafv2_web_acl.alb.arn
}

output "cf_logs_bucket_policy_status" {
  value = aws_s3_bucket_policy.cf_logs.id
}
