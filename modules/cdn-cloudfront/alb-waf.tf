

#=======================================================================
# Regional WAF on ALB
# Blocks any request that reaches the ALB without the correct
# X-Origin-Verify header — preventing CloudFront bypass attacks.
#
# The header value must match var.origin_verify_secret exactly.
# CloudFront injects this header on every request (distribution.tf).
#=======================================================================

resource "aws_wafv2_web_acl" "alb" {
  name        = "${local.name}-alb-waf"
  scope       = "REGIONAL"
  description = "ALB WAF — enforces X-Origin-Verify to block CloudFront bypass"

  default_action {
    block {}
  }

  rule {
    name     = "AllowCloudFrontOriginVerify"
    priority = 1

    action {
      allow {}
    }

    statement {
      byte_match_statement {
        search_string = var.origin_verify_secret
        field_to_match {
          single_header {
            name = "x-origin-verify"
          }
        }
        text_transformations {
          priority = 0
          type     = "NONE"
        }
        positional_constraint = "EXACTLY"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ALBOriginVerify"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name}-alb-waf-metrics"
    sampled_requests_enabled   = true
  }

  tags = local.tags
}


resource "aws_wafv2_web_acl_association" "alb" {
  count        = var.alb_arn != "" ? 1 : 0
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.alb.arn
}


