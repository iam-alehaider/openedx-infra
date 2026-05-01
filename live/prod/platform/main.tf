#=======================================================================
# Platform layer — prod
#
# Creates EKS cluster, node groups, IRSA roles, EFS.
# Reads networking state to get VPC/subnet IDs.
#
# Dependency: networking must be applied first.
# If networking state does not exist, terraform init will succeed but
# terraform plan will fail with a clear error at the remote_state read.
#
# DEV vs PROD differences (controlled by terraform.tfvars):
#   node_instance_type             = t3.medium  (vs m5.xlarge in prod)
#   node_min/max/desired           = 1/3/1      (vs 3/10/3 in prod)
#   cluster_endpoint_public_access = true       (vs false in prod)
#   cluster_log_types              = api,audit  (vs all 5 in prod)
#   cluster_log_retention_days     = 7          (vs 90 in prod)
#   efs_throughput_mode            = bursting   (vs elastic in prod)
#=======================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
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
      Layer       = "platform"
    }
  }
}

#-----------------------------------------------------------------------
# Consume networking outputs
# If this read fails: networking layer has not been applied yet.
#-----------------------------------------------------------------------
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "openedx-terraform-state"
    key    = "live/${var.environment}/networking/terraform.tfstate"
    region = var.region
  }
}

locals {
  vpc_id             = data.terraform_remote_state.networking.outputs.vpc_id
  vpc_cidr           = data.terraform_remote_state.networking.outputs.vpc_cidr
  private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.networking.outputs.public_subnet_ids
}

#-----------------------------------------------------------------------
# EKS Cluster
#-----------------------------------------------------------------------
module "eks" {
  source = "../../../modules/eks"

  project      = var.project
  environment  = var.environment
  cluster_name = "${var.project}-${var.environment}"

  cluster_version = var.cluster_version

  vpc_id             = local.vpc_id
  vpc_cidr           = local.vpc_cidr
  private_subnet_ids = local.private_subnet_ids
  public_subnet_ids  = local.public_subnet_ids

  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = true
  cluster_endpoint_public_cidrs   = var.developer_cidrs

  cluster_log_types          = var.cluster_log_types
  cluster_log_retention_days = var.cluster_log_retention_days

  node_groups = {
    general = {
      instance_types = [var.node_instance_type]
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
      capacity_type  = "ON_DEMAND"
      disk_size_gb   = var.node_disk_size_gb
      labels         = { role = "general" }
      taints         = []
    }
  }

  addon_versions = var.addon_versions
  tags           = var.tags
}



#-----------------------------------------------------------------------
# EFS Persistent Storage
#-----------------------------------------------------------------------
module "efs" {
  source = "../../../modules/efs"

  project     = var.project
  environment = var.environment

  vpc_id             = local.vpc_id
  vpc_cidr           = local.vpc_cidr
  private_subnet_ids = local.private_subnet_ids

  allowed_security_group_ids = [module.eks.node_security_group_id]
  allowed_role_arns          = [module.eks.node_role_arn]

  throughput_mode  = var.efs_throughput_mode
  transition_to_ia = "AFTER_30_DAYS"

  openedx_uid = 1000
  openedx_gid = 1000

  tags = var.tags
}
