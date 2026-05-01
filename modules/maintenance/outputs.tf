

#-----------------------------------------------------------------------
# Outputs — use these values in dns-route53 module tfvars
#-----------------------------------------------------------------------
output "maintenance_website_endpoint" {
  value       = aws_s3_bucket_website_configuration.maintenance.website_endpoint
  description = "Use this as lms_failover_domain and cms_failover_domain in dns-route53 tfvars"
}

output "maintenance_bucket_name" {
  value       = aws_s3_bucket.maintenance.id
  description = "S3 bucket name for the maintenance page"
}

# This zone ID is fixed for S3 website endpoints in us-east-1.
# If your S3 bucket is in a different region, find the correct
# zone ID at: https://docs.aws.amazon.com/general/latest/gr/s3.html

output "maintenance_zone_id" {
  value       = local.maintenance_zone_id
  description = "Use this as lms_failover_zone_id and cms_failover_zone_id"
}
