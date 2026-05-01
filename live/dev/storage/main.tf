
#=======================================================================
# Storage layer — dev
#
# Creates S3 buckets for application data (static, media, uploads).
# Independent — reads no upstream state.
# Can be applied in parallel with platform and data layers.
#=======================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Layer       = "storage"
    }
  }
}

module "platform_storage" {
  source = "../../../modules/platform-storage"

  project     = var.project
  environment = var.environment

  cors_allowed_origins = var.cors_allowed_origins

  tags = var.tags
}
