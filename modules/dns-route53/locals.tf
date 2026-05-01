
locals {
  name = "${var.project}-${var.environment}"

  tags = merge({
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)

  # FIX: Use explicit root_domain variable instead of fragile split/join parsing
  # Previous: join(".", slice(split(".", var.lms_domain), 1, length(...)))
  # That breaks on multi-level TLDs like .co.uk or sub-subdomains
  root_domain = var.root_domain
}

