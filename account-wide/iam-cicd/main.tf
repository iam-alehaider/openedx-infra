#=======================================================================
# GitHub Actions IAM Roles — account-wide
#
# OIDC trust roles for CI/CD. Applied once.
# No upstream dependencies.
#=======================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket         = "openedx-terraform-state"
    key            = "account-wide/iam-cicd/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "openedx-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "openedx"
      ManagedBy = "terraform"
      Layer     = "account-wide-iam-cicd"
    }
  }
}

module "iam_cicd_dev" {
  source             = "../../modules/iam-github-actions"
  project            = "openedx"
  environment        = "dev"
  github_org         = "your-org"
  github_repo        = "openedx-infra"
  github_main_branch = "main"
  eks_cluster_name   = "openedx-dev"
  ecr_repository_names = ["lms", "cms", "mfe", "notes", "discovery", "forum"]
  tags               = { Scope = "account-wide" }
}

module "iam_cicd_staging" {
  source             = "../../modules/iam-github-actions"
  project            = "openedx"
  environment        = "staging"
  github_org         = "your-org"
  github_repo        = "openedx-infra"
  github_main_branch = "main"
  eks_cluster_name   = "openedx-staging"
  ecr_repository_names = ["lms", "cms", "mfe", "notes", "discovery", "forum"]
  tags               = { Scope = "account-wide" }
}

module "iam_cicd_prod" {
  source             = "../../modules/iam-github-actions"
  project            = "openedx"
  environment        = "prod"
  github_org         = "your-org"
  github_repo        = "openedx-infra"
  github_main_branch = "main"
  eks_cluster_name   = "openedx-prod"
  ecr_repository_names = ["lms", "cms", "mfe", "notes", "discovery", "forum"]
  tags               = { Scope = "account-wide" }
}
