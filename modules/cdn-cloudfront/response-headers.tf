
#=======================================================================
# CloudFront Response Headers Policy
# Injects security headers into every response CloudFront serves.
# Covers HSTS, clickjacking, MIME sniffing, referrer, XSS protection.
# CSP is intentionally permissive here — tighten per your app needs.
# Start with report-only mode in staging before enforcing in prod.
#=======================================================================

resource "aws_cloudfront_response_headers_policy" "security" {
  provider = aws.us_east_1
  name     = "${local.name}-security-headers"
  comment  = "Security headers injected on all CloudFront behaviors"

  security_headers_config {

    strict_transport_security {
      access_control_max_age_sec = 31536000  # 1 year
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    content_type_options {
      override = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
  }

  custom_headers_config {
    items {
      header = "Content-Security-Policy"
      value    = "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; object-src 'none'; frame-ancestors 'none'"
      override = true
    }
  }

}
