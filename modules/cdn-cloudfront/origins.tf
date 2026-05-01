

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${local.name}-s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}



resource "aws_s3_bucket_policy" "static_oac" {
  bucket = var.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontOAC"
      Effect = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action   = "s3:GetObject"
      Resource = "${var.s3_bucket_arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
        }
      }
    }]
  })

  # ADD THIS BLOCK:
  # If the distribution is recreated its ARN changes. create_before_destroy
  # ensures the new policy (with new ARN) is applied before the old distribution
  # is deleted, so S3 never serves 403s during the transition.
  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [aws_cloudfront_distribution.main]
  }
}


