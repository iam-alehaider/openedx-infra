
# ── Route53 Query Logging ──
# Added query logging for DNS abuse detection and visibility

resource "aws_cloudwatch_log_group" "route53_query_logs" {
  # Route53 query logs must go to us-east-1
  provider          = aws.us_east_1
  name              = "/aws/route53/${local.root_domain}"
  retention_in_days = var.query_log_retention_days
  tags              = local.tags
}

resource "aws_route53_query_log" "main" {
  depends_on = [aws_cloudwatch_log_resource_policy.route53]

  cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_logs.arn
  zone_id                  = data.aws_route53_zone.main.zone_id
}


# Route53 needs permission to write query logs to CloudWatch

resource "aws_cloudwatch_log_resource_policy" "route53" {
  provider    = aws.us_east_1 
  policy_name = "route53-query-logging-${local.name}"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "route53.amazonaws.com"
      }
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.route53_query_logs.arn}:*"
    }]
  })
}
