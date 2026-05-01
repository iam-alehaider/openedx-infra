

#================================================
# Cache Policy: Dynamic (LMS/CMS pages)
#================================================

resource "aws_cloudfront_cache_policy" "dynamic" {
  name        = "${local.name}-dynamic-cache-policy"
  comment     = "No caching for dynamic LMS/CMS content"
  default_ttl = 0
  min_ttl     = 0
  max_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "all"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Authorization", "Host", "CloudFront-Forwarded-Proto"]
      }
    }
    query_strings_config {
      query_string_behavior = "all"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

#=======================================================================
# Cache Policy: Static Assets
# Long TTL for versioned static files (CSS, JS, images from S3)
#=======================================================================

resource "aws_cloudfront_cache_policy" "static" {
  name        = "${local.name}-static-cache-policy"
  comment     = "Long-lived caching for static assets from S3"
  default_ttl = 604800   # 7 days
  min_ttl     = 86400    # 1 day
  max_ttl     = 31536000 # 1 year

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

#================================================
# Cache Policy: Media Files
#================================================

resource "aws_cloudfront_cache_policy" "media" {
  name        = "${local.name}-media-cache-policy"
  comment     = "Medium-lived caching for user-uploaded media from S3"
  default_ttl = 86400   # 1 day
  min_ttl     = 3600    # 1 hour
  max_ttl     = 604800  # 7 days

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

#=======================================================================
# Origin Request Policy: ALB
# Controls what gets forwarded to the ALB origin (not cached)
#=======================================================================

resource "aws_cloudfront_origin_request_policy" "alb" {
  name    = "${local.name}-alb-origin-request-policy"
  comment = "Forward required headers/cookies to ALB"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Host", "Authorization", "CloudFront-Forwarded-Proto", "X-Forwarded-For"]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

