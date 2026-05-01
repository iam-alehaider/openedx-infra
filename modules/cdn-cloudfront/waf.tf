
resource "aws_wafv2_ip_set" "blocked" {
  provider           = aws.us_east_1
  name               = "${local.name}-blocked-ips"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.waf_blocked_ip_cidrs
  tags               = local.tags
}

resource "aws_wafv2_ip_set" "admin_allowed" {
  count              = local.enable_admin_ip_allowlist ? 1 : 0
  provider           = aws.us_east_1
  name               = "${local.name}-admin-allowed-ips"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.admin_allowed_ip_cidrs
  tags               = local.tags
}

resource "aws_wafv2_web_acl" "cloudfront" {
  provider    = aws.us_east_1
  name        = "${local.name}-cloudfront-waf"
  scope       = "CLOUDFRONT"
  description = "WAF for ${local.name} CloudFront distribution"
  
  # Traffic not matched by any blocking rule below is allowed through.
  # Blocking is handled explicitly by rules at priorities 0–80.
  # This model (allow-by-default, block-by-exception) is appropriate here
  # because CloudFront already requires HTTPS and the WAF rules cover all
  # known threat vectors. Use default_action { block {} } only if you want
  # an explicit allowlist model, which requires an additional allow rule
  # for all legitimate traffic patterns.
  
  default_action {
    allow {}
  }

  #---------------------------------------------------------------------
  # P1 — Explicit block for IPs in the blocklist (priority 0)
  # Moved to priority 0 and made a hard block so it terminates first.
  #---------------------------------------------------------------------
  dynamic "rule" {
    for_each = length(var.waf_blocked_ip_cidrs) > 0 ? [1] : []
    content {
      name     = "BlocklistedIPs"
      priority = 0

      action {
        block {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.blocked.arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "BlocklistedIPs"
        sampled_requests_enabled   = true
      }
    }
  }

  #---------------------------------------------------------------------
  # P1 — Bot Control (priority 10)
  # Uses rule_action_override to actually BLOCK known bad bot categories.
  # override_action=none means the rule's own actions fire per-category.
  # Without overrides, Bot Control only labels — it does NOT block.
  #---------------------------------------------------------------------
  dynamic "rule" {
    for_each = var.enable_bot_control ? [1] : []
    content {
      name     = "AWSBotControl"
      priority = 10

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesBotControlRuleSet"
          vendor_name = "AWS"

          managed_rule_group_configs {
            aws_managed_rules_bot_control_rule_set {
              inspection_level = "COMMON"
            }
          }

          # Without these overrides, Bot Control only LABELS requests.
          # These override the default COUNT action to BLOCK for the
          # most clearly malicious bot categories.
          rule_action_override {
            name = "CategoryHttpLibrary"
            action_to_use { block {} }
          }
          rule_action_override {
            name = "SignalNonBrowserUserAgent"
            action_to_use { block {} }
          }
          rule_action_override {
            name = "CategoryMonitoring"
            action_to_use { block {} }
          }
          rule_action_override {
            name = "CategoryScrapingFramework"
            action_to_use { block {} }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "BotControl"
        sampled_requests_enabled   = true
      }
    }
  }



  
  #---------------------------------------------------------------------
  # P1 — Geo restriction (priority 20)
  #---------------------------------------------------------------------
  dynamic "rule" {
    for_each = var.enable_geo_restriction && length(var.geo_blocked_country_codes) > 0 ? [1] : []
    content {
      name     = "GeoRestriction"
      priority = 20

      action {
        block {}
      }

      statement {
        geo_match_statement {
          country_codes = var.geo_blocked_country_codes
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "GeoRestriction"
        sampled_requests_enabled   = true
      }
    }
  }

  #---------------------------------------------------------------------
  # P3 — Admin path IP allowlist (priority 30)
  #---------------------------------------------------------------------
  dynamic "rule" {
    for_each = local.enable_admin_ip_allowlist ? [1] : []
    content {
      name     = "AdminIPAllowlist"
      priority = 30

      action {
        block {}
      }

      statement {
        and_statement {
          statement {
            byte_match_statement {
              search_string = "/admin/"
              field_to_match {
                uri_path {}
              }
              text_transformations {
                priority = 0
                type     = "LOWERCASE"
              }
              positional_constraint = "STARTS_WITH"
            }
          }
          statement {
            not_statement {
              statement {
                ip_set_reference_statement {
                  arn = aws_wafv2_ip_set.admin_allowed[0].arn
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AdminIPAllowlist"
        sampled_requests_enabled   = true
      }
    }
  }

  #---------------------------------------------------------------------
  # P3 — /login strict rate limit (priority 40)
  # 50 req/5min per IP. Catches credential stuffing.
  #---------------------------------------------------------------------
  rule {
    name     = "LoginRateLimit"
    priority = 40

    action {
      captcha {} 
    }

    statement {
      rate_based_statement {
        limit              = var.login_rate_limit
        aggregate_key_type = "IP"

        scope_down_statement {
          byte_match_statement {
            search_string = "/login"
            field_to_match {
              uri_path {}
            }
            text_transformations {
              priority = 0
              type     = "LOWERCASE"
            }
            positional_constraint = "CONTAINS"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "LoginRateLimit"
      sampled_requests_enabled   = true
    }
  }

  #---------------------------------------------------------------------
  # P3 — /api/* rate limit (priority 50)
  #---------------------------------------------------------------------
  rule {
    name     = "APIRateLimit"
    priority = 50

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_api_rate_limit
        aggregate_key_type = "IP"

        scope_down_statement {
          byte_match_statement {
            search_string = "/api/"
            field_to_match {
              uri_path {}
            }
            text_transformations {
              priority = 0
              type     = "LOWERCASE"
            }
            positional_constraint = "STARTS_WITH"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "APIRateLimit"
      sampled_requests_enabled   = true
    }
  }

  
  
  #---------------------------------------------------------------------
  # AWS Common Rule Set (priority 60)
  # override_action=none means each rule fires its own action (block/count).
  #---------------------------------------------------------------------
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 60

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        # SizeRestrictions_BODY fires on large POST bodies and can cause
        # false positives on course upload endpoints. Use 'count' in staging
        # to review false positives, set to 'block' in prod via tfvars.
        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            dynamic "count" {
              for_each = var.waf_body_size_restriction_action == "count" ? [1] : []
              content {}
            }
            dynamic "block" {
              for_each = var.waf_body_size_restriction_action == "block" ? [1] : []
              content {}
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }
  
  #---------------------------------------------------------------------
  # AWS Known Bad Inputs (priority 70)
  #---------------------------------------------------------------------
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 70

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputs"
      sampled_requests_enabled   = true
    }
  }
  

  #---------------------------------------------------------------------
  # Anonymous IP list (priority 75)
  # Blocks Tor exit nodes, known VPNs, hosting ranges used for attacks.
  #---------------------------------------------------------------------
  rule {
    name     = "AWSManagedRulesAnonymousIpList"
    priority = 75

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"

        # HostingProviderIPList blocks all cloud datacenter IPs broadly.
        # This breaks legitimate API clients in AWS/GCP/Azure — count only.
        rule_action_override {
          name = "HostingProviderIPList"
          action_to_use { count {} }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AnonymousIPs"
      sampled_requests_enabled   = true
    }
  }




  #---------------------------------------------------------------------
  # General rate limit (priority 90)
  # Catch-all fallback.
  #---------------------------------------------------------------------
  rule {
    name     = "RateLimitRule"
    priority = 90

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name}-waf-metrics"
    sampled_requests_enabled   = true
  }

  tags = local.tags
}
