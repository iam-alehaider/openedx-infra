

locals {
  name = "${var.project}-${var.environment}"

  tags = merge({
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)

  # Feature flags derived from variables
  enable_admin_ip_allowlist = length(var.admin_allowed_ip_cidrs) > 0
  enable_jwt_edge           = var.jwt_public_key_ssm_path != "" || var.jwt_public_keys_ssm_path != ""
  enable_opensearch         = var.opensearch_endpoint != ""
}
