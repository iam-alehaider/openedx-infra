
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
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
      Layer       = "edge"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

#-----------------------------------------------------------------------
# Read upstream layer outputs
#-----------------------------------------------------------------------
data "terraform_remote_state" "data" {
  backend = "s3"
  config = {
    bucket = "openedx-terraform-state"
    key    = "live/${var.environment}/data/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "storage" {
  backend = "s3"
  config = {
    bucket = "openedx-terraform-state"
    key    = "live/${var.environment}/storage/terraform.tfstate"
    region = var.region
  }
}

#-----------------------------------------------------------------------
# Read the origin-verify secret value at apply time
# The secret was created by the data layer's secrets module
#-----------------------------------------------------------------------
data "aws_secretsmanager_secret_version" "origin_verify" {
  secret_id = data.terraform_remote_state.data.outputs.origin_verify_secret_arn
}


#-----------------------------------------------------------------------
# ACM Certificate — created here (not inside dns module) to break the
# circular dependency: cdn needs the cert ARN, dns needs CloudFront's
# domain. By owning the cert at this layer, cdn gets the ARN directly
# and dns only needs cdn's output, which flows in one direction.
#-----------------------------------------------------------------------
data "aws_route53_zone" "main" {
  name         = "${var.root_domain}."
  private_zone = false
  provider     = aws.us_east_1
}

resource "aws_acm_certificate" "main" {
  provider                  = aws.us_east_1
  domain_name               = var.lms_domain
  subject_alternative_names = [var.cms_domain, "*.${var.root_domain}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  provider = aws.us_east_1
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "main" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

#-----------------------------------------------------------------------
# DNS + ACM Certificate
# Note: certificate_arn feeds into cdn module below.
# Terraform resolves this dependency automatically within this layer.
#-----------------------------------------------------------------------
module "dns" {
  source = "../../../modules/dns-route53"

  project     = var.project
  environment = var.environment

  lms_domain        = var.lms_domain
  cms_domain        = var.cms_domain
  root_domain       = var.root_domain
  cloudfront_domain = module.cdn.distribution_domain

  lms_failover_domain  = var.lms_failover_domain
  lms_failover_zone_id = var.lms_failover_zone_id
  cms_failover_domain  = var.cms_failover_domain
  cms_failover_zone_id = var.cms_failover_zone_id

  query_log_retention_days = var.cf_log_retention_days

  tags = var.tags

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}


#-----------------------------------------------------------------------
# CloudFront CDN + WAF
#-----------------------------------------------------------------------

locals {
  origin_verify_secret = sensitive(data.aws_secretsmanager_secret_version.origin_verify.secret_string)
}


module "cdn" {
  source = "../../../modules/cdn-cloudfront"

  project     = var.project
  environment = var.environment

  alb_dns_name = var.alb_dns_name
  alb_arn      = var.alb_arn

  s3_bucket_regional_domain = "${data.terraform_remote_state.storage.outputs.storage_bucket_name}.s3.${var.region}.amazonaws.com"
  s3_bucket_arn             = data.terraform_remote_state.storage.outputs.storage_bucket_arn
  s3_bucket_id              = data.terraform_remote_state.storage.outputs.storage_bucket_name

  acm_certificate_arn  = aws_acm_certificate_validation.main.certificate_arn
  origin_verify_secret = local.origin_verify_secret

  domain_aliases = [var.lms_domain, var.cms_domain]

  price_class = var.price_class

  waf_rate_limit                   = var.waf_rate_limit
  waf_api_rate_limit               = var.waf_api_rate_limit
  login_rate_limit                 = var.login_rate_limit
  enable_bot_control               = var.enable_bot_control
  enable_geo_restriction           = var.enable_geo_restriction
  geo_blocked_country_codes        = var.geo_blocked_country_codes
  waf_body_size_restriction_action = var.waf_body_size_restriction_action

  enable_signed_media_urls = var.enable_signed_media_urls

  jwt_public_key_ssm_path  = var.jwt_public_key_ssm_path
  jwt_public_keys_ssm_path = var.jwt_public_keys_ssm_path
  jwt_issuer               = var.jwt_issuer
  jwt_audience             = var.jwt_audience

  cf_log_retention_days     = var.cf_log_retention_days
  waf_s3_log_retention_days = var.waf_s3_log_retention_days

  alarm_sns_topic_arn = data.terraform_remote_state.data.outputs.sns_topic_arn

  opensearch_endpoint    = var.opensearch_endpoint
  opensearch_domain_name = var.opensearch_domain_name

  tags = var.tags

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}
