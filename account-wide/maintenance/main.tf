
# account-wide/maintenance/main.tf
#
# Standalone maintenance page layer — applied ONCE, never destroyed.
# This fixes the count-inversion bug present in all three edge/main.tf files
# where the maintenance bucket was created/destroyed based on whether failover
# was configured, causing a race condition during failover activation.
#
# USAGE:
#   1. cd account-wide/maintenance && terraform apply
#   2. Copy outputs to each environment's edge/terraform.tfvars:
#        lms_failover_domain  = <maintenance_website_endpoint>
#        lms_failover_zone_id = <maintenance_zone_id>
#        cms_failover_domain  = <maintenance_website_endpoint>
#        cms_failover_zone_id = <maintenance_zone_id>
#   3. Apply the edge layer — health checks and DNS failover activate automatically.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }

  backend "s3" {
    bucket         = "openedx-terraform-state"
    key            = "account-wide/maintenance/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "openedx-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "openedx"
      ManagedBy = "terraform"
      Layer     = "account-wide-maintenance"
    }
  }
}

module "maintenance" {
  source = "../../modules/maintenance"

  project       = var.project
  environment   = var.environment
  bucket_region = var.region

  tags = var.tags
}

