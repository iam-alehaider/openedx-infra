locals {
  name = "${var.project}-${var.environment}"

  tags = merge({
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "rds"
  }, var.tags)
}
