
#==========================
# VPC Flow Logs
#========================

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs/${local.name}"
  retention_in_days = var.flow_log_retention_days
  tags              = local.tags
}

resource "aws_iam_role" "vpc_flow_log" {
  name = "${local.name}-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
  tags = local.tags
}

# FIX: Restrict resource to specific log group ARN (was "*" — violated least privilege)
resource "aws_iam_role_policy" "vpc_flow_log" {
  name = "${local.name}-vpc-flow-log-policy"
  role = aws_iam_role.vpc_flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      # FIX: was Resource = "*" — now scoped to specific log group
      Resource = [
        aws_cloudwatch_log_group.vpc_flow_logs.arn,
        "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      ]
    }]
  })
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  # FIX: Use REJECT in cost-sensitive environments; ALL in prod for full audit
  traffic_type    = var.flow_log_traffic_type
  vpc_id          = aws_vpc.main.id
  tags            = local.tags
}

