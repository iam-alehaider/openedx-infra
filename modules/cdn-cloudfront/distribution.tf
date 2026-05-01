


resource "aws_cloudfront_distribution" "main" {
  enabled         = true
  is_ipv6_enabled = true
  http_version    = "http2and3"
  price_class     = var.price_class
  aliases         = var.domain_aliases
  comment         = "OpenEdX ${var.environment} CDN"
  web_acl_id      = aws_wafv2_web_acl.cloudfront.arn

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cf_logs.bucket_domain_name
    prefix          = "cloudfront/"
  }

  #----------------------------------------------------------------------
  # ALB Origin
  #----------------------------------------------------------------------
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Origin-Verify"
      value = var.origin_verify_secret
    }
  }

  #----------------------------------------------------------------------
  # S3 Static/Media Origin
  #----------------------------------------------------------------------
  origin {
    domain_name              = var.s3_bucket_regional_domain
    origin_id                = "s3-static-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  #----------------------------------------------------------------------
  # Default behavior: LMS/CMS dynamic pages → ALB
  #----------------------------------------------------------------------
  default_cache_behavior {
    target_origin_id         = "alb-origin"
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = aws_cloudfront_cache_policy.dynamic.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.alb.id
    compress                 = true
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  #----------------------------------------------------------------------
  # P2 ── /api/* behavior: ALB + Lambda@Edge JWT validation
  #       Lambda@Edge (viewer-request) checks the Authorization header
  #       BEFORE the request reaches CloudFront's cache or the ALB.
  #       Unauthenticated requests get a 401 at the edge.
  #
  #       When enable_jwt_edge = false (jwt_public_key_ssm_path = ""),
  #       this behavior is omitted and /api/* falls through to default.
  #----------------------------------------------------------------------
  dynamic "ordered_cache_behavior" {
    for_each = local.enable_jwt_edge ? [1] : []
    content {
      path_pattern             = "/api/*"
      target_origin_id         = "alb-origin"
      viewer_protocol_policy   = "redirect-to-https"
      allowed_methods          = ["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
      cached_methods           = ["GET", "HEAD"]
      cache_policy_id          = aws_cloudfront_cache_policy.dynamic.id
      origin_request_policy_id = aws_cloudfront_origin_request_policy.alb.id
      compress                 = true
      response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

      lambda_function_association {
        event_type   = "viewer-request"
        lambda_arn   = aws_lambda_function.edge_jwt[0].qualified_arn
        include_body = false
      }
    }
  }

  #----------------------------------------------------------------------
  # Static Assets: long cache from S3
  #----------------------------------------------------------------------
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "s3-static-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = aws_cloudfront_cache_policy.static.id
    compress               = true
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  #----------------------------------------------------------------------
  # P2 ── /media/* behavior: S3 + signed URL enforcement
  #       When enable_signed_media_urls = true, CloudFront validates
  #       the request signature against the key group. Unsigned requests
  #       receive a 403 — even if they know the S3 URL.
  #
  #       The application generates signed URLs using the private key
  #       stored in Secrets Manager and embeds them in HTML/API responses.
  #
  #       When enable_signed_media_urls = false (dev), /media/* is served
  #       without signature enforcement (still requires OAC for S3).
  #----------------------------------------------------------------------
  ordered_cache_behavior {
    path_pattern           = "/media/*"
    target_origin_id       = "s3-static-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = aws_cloudfront_cache_policy.media.id
    compress               = true
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    # Attach key group only when signed URLs are enabled
    trusted_key_groups = var.enable_signed_media_urls ? [
      aws_cloudfront_key_group.media_signing[0].id
    ] : []
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
     geo_restriction {
       restriction_type = "none"
     }
  }

  custom_error_response {                          # ← ADD FROM HERE
    error_code            = 403
    response_code         = 403
    response_page_path    = "/static/error/403.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/static/error/404.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 500
    response_code         = 500
    response_page_path    = "/static/error/500.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 502
    response_code         = 502
    response_page_path    = "/static/error/500.html"
    error_caching_min_ttl = 0
  }                                                # ← TO HERE

  tags = merge(local.tags, { Name = "${local.name}-cloudfront" })
}
