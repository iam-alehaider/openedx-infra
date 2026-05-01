
output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value     = module.eks.cluster_endpoint
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = module.eks.cluster_ca_certificate
  sensitive = true
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  value = module.eks.oidc_provider_url
}

output "node_security_group_id" {
  value = module.eks.node_security_group_id
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "node_role_arn" {
  value = module.eks.node_role_arn
}

output "openedx_s3_role_arn" {
  value = module.eks.openedx_s3_role_arn
}

output "cluster_autoscaler_role_arn" {
  value = module.eks.cluster_autoscaler_role_arn
}

output "kms_key_arn" {
  value = module.eks.kms_key_arn
}

output "efs_file_system_id" {
  value = module.efs.file_system_id
}

output "efs_access_point_id" {
  value = module.efs.access_point_id
}

output "efs_security_group_id" {
  value = module.efs.security_group_id
}

output "efs_dns_name" {
  value = module.efs.dns_name
}
