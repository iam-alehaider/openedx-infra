
output "maintenance_website_endpoint" {
  description = "Use as lms_failover_domain and cms_failover_domain in all edge tfvars"
  value       = module.maintenance.maintenance_website_endpoint
}

output "maintenance_zone_id" {
  description = "Use as lms_failover_zone_id and cms_failover_zone_id in all edge tfvars"
  value       = module.maintenance.maintenance_zone_id
}

output "maintenance_bucket_name" {
  value = module.maintenance.maintenance_bucket_name
}

