
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
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
      Layer       = "data"
    }
  }
}

data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "openedx-terraform-state"
    key    = "live/${var.environment}/networking/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "platform" {
  backend = "s3"
  config = {
    bucket = "openedx-terraform-state"
    key    = "live/${var.environment}/platform/terraform.tfstate"
    region = var.region
  }
}

locals {
  vpc_id                 = data.terraform_remote_state.networking.outputs.vpc_id
  vpc_cidr               = data.terraform_remote_state.networking.outputs.vpc_cidr
  private_subnet_ids     = data.terraform_remote_state.networking.outputs.private_subnet_ids
  database_subnet_ids    = data.terraform_remote_state.networking.outputs.database_subnet_ids
  node_security_group_id = data.terraform_remote_state.platform.outputs.node_security_group_id
}

#-----------------------------------------------------------------------
# Secrets (must be created before data stores that read from them)
#-----------------------------------------------------------------------
module "secrets" {
  source = "../../../modules/secrets"

  project     = var.project
  environment = var.environment

  redis_reader_role_arns      = var.redis_reader_role_arns
  opensearch_reader_role_arns = var.opensearch_reader_role_arns

  tags = var.tags
}

#-----------------------------------------------------------------------
# RDS MySQL
#-----------------------------------------------------------------------
module "rds" {
  source = "../../../modules/rds"

  project     = var.project
  environment = var.environment

  vpc_id     = local.vpc_id
  vpc_cidr   = local.vpc_cidr
  subnet_ids = local.database_subnet_ids

  allowed_security_group_ids = [local.node_security_group_id]

  instance_class        = var.rds_instance_class
  allocated_storage     = 20
  max_allocated_storage = var.rds_max_allocated_storage

  multi_az            = var.rds_multi_az
  deletion_protection = var.rds_deletion_protection
  backup_retention    = var.rds_backup_retention

  performance_insights_enabled = var.rds_performance_insights_enabled

  cloudwatch_log_exports = ["error", "slowquery"]

  proxy_role_arn = var.rds_proxy_role_arn

  tags = var.tags
}

#-----------------------------------------------------------------------
# ElastiCache Redis
#-----------------------------------------------------------------------
module "elasticache" {
  source = "../../../modules/elasticache"

  project     = var.project
  environment = var.environment

  vpc_id     = local.vpc_id
  vpc_cidr   = local.vpc_cidr
  subnet_ids = local.private_subnet_ids

  allowed_security_group_ids = [local.node_security_group_id]

  node_type        = var.redis_node_type
  replica_count    = var.redis_replica_count
  multi_az_enabled = var.redis_multi_az

  redis_secret_arn = module.secrets.redis_secret_arn

  snapshot_retention_days = var.redis_snapshot_retention_days
  deletion_protection     = var.redis_deletion_protection

  tags = var.tags
}

#-----------------------------------------------------------------------
# OpenSearch — disabled in dev, enabled in prod via tfvars
#-----------------------------------------------------------------------
module "opensearch" {
  source = "../../../modules/opensearch"
  count  = var.enable_opensearch ? 1 : 0

  project     = var.project
  environment = var.environment

  vpc_id     = local.vpc_id
  vpc_cidr   = local.vpc_cidr
  subnet_ids = local.private_subnet_ids

  allowed_security_group_ids = [local.node_security_group_id]

  instance_type  = var.opensearch_instance_type
  instance_count = var.opensearch_instance_count
  volume_size_gb = var.opensearch_volume_size_gb

  master_password_secret_arn = module.secrets.opensearch_secret_arn

  log_retention_days = var.opensearch_log_retention_days

  tags = var.tags
}

#-----------------------------------------------------------------------
# Monitoring — alarms for RDS and Redis
#-----------------------------------------------------------------------
module "monitoring" {
  source = "../../../modules/monitoring"

  project     = var.project
  environment = var.environment

  alarm_email          = var.alarm_email
  rds_identifier       = module.rds.db_identifier
  redis_replication_id = module.elasticache.replication_group_id

  enable_opensearch_alarms = var.enable_opensearch
  opensearch_domain_name   = var.enable_opensearch ? module.opensearch[0].domain_name : ""

  tags = var.tags
}
