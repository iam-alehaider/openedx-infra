
#=======================================================================
# Networking layer — staging
#
# Creates VPC, subnets, NAT gateways, VPC endpoints, NACLs.
# Outputs are consumed by: platform, data, edge via remote state.
#
# This layer has NO upstream dependencies.
# It is the root of the dependency graph.
#
# DEV vs PROD differences (controlled entirely by terraform.tfvars):
#   single_nat_gateway      = true   (dev saves ~$130/month)
#   flow_log_traffic_type   = REJECT (dev: cheaper, less data)
#   flow_log_retention_days = 7      (dev: shorter retention)
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
      Layer       = "networking"
    }
  }
}

module "vpc" {
  source = "../../../modules/vpc"

  project     = var.project
  environment = var.environment
  region      = var.region

  vpc_cidr         = var.vpc_cidr
  azs              = var.azs
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets

  cluster_name = "${var.project}-${var.environment}"

  enable_nat_gateway      = true
  single_nat_gateway      = var.single_nat_gateway
  flow_log_traffic_type   = var.flow_log_traffic_type
  flow_log_retention_days = var.flow_log_retention_days

  tags = var.tags
}
