


locals {
  name = "${var.project}-${var.environment}"
  tags = merge({
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)

  # ADD THIS BELOW ↓
  # S3 website hosted zone IDs differ per region.
  # Full list: https://docs.aws.amazon.com/general/latest/gr/s3.html
  s3_website_zone_ids = {
    "us-east-1"      = "Z3AQBSTGFYJSTF"
    "us-east-2"      = "Z2O1EMRO9K5GLX"
    "us-west-1"      = "Z2F56UZL2M1ACD"
    "us-west-2"      = "Z3BJ6K6RIION7M"
    "eu-west-1"      = "Z1BKCTXD74EZPE"
    "eu-west-2"      = "Z3GKZC51ZF0DB4"
    "eu-central-1"   = "Z21DNDUVLTQW6Q"
    "ap-southeast-1" = "Z3O0J2DXBE1FTB"
    "ap-southeast-2" = "Z1WCIGYICN2BYD"
    "ap-northeast-1" = "Z2M4EHUR26P7ZW"
  }
  maintenance_zone_id = local.s3_website_zone_ids[var.bucket_region]
}

