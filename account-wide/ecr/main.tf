#=======================================================================
# ECR Repositories — account-wide
#
# ECR is NOT per-environment. All environments push to the same
# registry. Only the image tag differentiates dev/staging/prod.
# Example:
#   sha-abc123  → built from a commit, tested in dev
#   v1.2.3      → release tag, deployed to prod
#
# Pull access: prod EKS node role (also used by staging/dev node roles)
# Push access: GitHub Actions CI role
#
# Run this AFTER:
#   account-wide/iam-cicd (for push role ARN)
#   live/prod/platform    (for pull role ARN)
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
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "openedx"
      ManagedBy = "terraform"
      Layer     = "account-wide-ecr"
    }
  }
}

data "terraform_remote_state" "prod_platform" {
  backend = "s3"
  config = {
    bucket = "openedx-terraform-state"
    key    = "live/prod/platform/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "iam_cicd" {
  backend = "s3"
  config = {
    bucket = "openedx-terraform-state"
    key    = "account-wide/iam-cicd/terraform.tfstate"
    region = "us-east-1"
  }
}

module "ecr" {
  source = "../../modules/ecr"

  project     = "openedx"
  environment = "shared"

  repositories          = ["lms", "cms", "mfe", "notes", "discovery", "forum"]
  image_retention_count = 30
  image_tag_prefixes    = ["v", "sha-", "release-"]

  allowed_pull_role_arns = [
    data.terraform_remote_state.prod_platform.outputs.node_role_arn
  ]

  allowed_push_role_arns = [
    data.terraform_remote_state.iam_cicd.outputs.github_ecr_push_role_arn
  ]

  tags = { Scope = "account-wide" }
}
