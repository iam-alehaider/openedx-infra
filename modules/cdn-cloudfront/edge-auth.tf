



# ── IAM role (unchanged) ───────────────────────────────────────────────

data "aws_iam_policy_document" "edge_lambda_assume" {
  count = local.enable_jwt_edge ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "edgelambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "edge_jwt" {
  count              = local.enable_jwt_edge ? 1 : 0
  provider           = aws.us_east_1
  name               = "${local.name}-edge-jwt-validator"
  assume_role_policy = data.aws_iam_policy_document.edge_lambda_assume[0].json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "edge_jwt_basic" {
  count      = local.enable_jwt_edge ? 1 : 0
  provider   = aws.us_east_1
  role       = aws_iam_role.edge_jwt[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ── NEW: SSM read permission for Lambda ───────────────────────────────

resource "aws_iam_role_policy" "edge_jwt_ssm" {
  count    = local.enable_jwt_edge ? 1 : 0
  provider = aws.us_east_1
  name     = "${local.name}-edge-jwt-ssm"
  role     = aws_iam_role.edge_jwt[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["ssm:GetParameter"]
      Resource = compact([
        var.jwt_public_key_ssm_path != "" ? "arn:aws:ssm:us-east-1:*:parameter${var.jwt_public_key_ssm_path}" : "",
        var.jwt_public_keys_ssm_path != "" ? "arn:aws:ssm:us-east-1:*:parameter${var.jwt_public_keys_ssm_path}" : "",
      ])
    }]
  })
}

# ── NEW: Build Lambda zip from template (key fetched at runtime) ──────

locals {
  edge_jwt_source = local.enable_jwt_edge ? templatefile("${path.module}/lambda/jwt-validator/index.js.tpl", {
    ssm_single_path   = var.jwt_public_key_ssm_path
    ssm_multi_path    = var.jwt_public_keys_ssm_path
    expected_issuer   = var.jwt_issuer
    expected_audience = var.jwt_audience
  }) : ""
}

resource "local_file" "edge_jwt_rendered" {
  count    = local.enable_jwt_edge ? 1 : 0
  filename = "${path.module}/.lambda-build/jwt-validator/index.js"
  content  = local.edge_jwt_source
}

data "archive_file" "edge_jwt" {
  count       = local.enable_jwt_edge ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/.lambda-build/jwt-validator"
  output_path = "${path.module}/.lambda-build/jwt-validator.zip"
  depends_on  = [local_file.edge_jwt_rendered]
}

# ── Lambda function (add lifecycle block) ────────────────────────────

resource "aws_lambda_function" "edge_jwt" {
  count            = local.enable_jwt_edge ? 1 : 0
  provider         = aws.us_east_1
  function_name    = "${local.name}-edge-jwt-validator"
  role             = aws_iam_role.edge_jwt[0].arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.edge_jwt[0].output_path
  source_code_hash = data.archive_file.edge_jwt[0].output_base64sha256
  publish          = true

  memory_size = 128
  timeout     = 5

  # ADDED: prevents 45-min destroy hang when Lambda is replicated to edge
  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

# ── Signed media URL key group (unchanged) ────────────────────────────

resource "aws_cloudfront_public_key" "media_signing" {
  count       = var.enable_signed_media_urls ? 1 : 0
  provider    = aws.us_east_1
  name        = "${local.name}-media-signing-key"
  comment     = "Public key for CloudFront signed URLs on /media/* — rotate annually"
  encoded_key = file("${path.module}/cf_media_public.pem")
}

resource "aws_cloudfront_key_group" "media_signing" {
  count    = var.enable_signed_media_urls ? 1 : 0
  provider = aws.us_east_1
  name     = "${local.name}-media-signing-key-group"
  comment  = "Key group for /media/* signed URL enforcement"
  items    = [aws_cloudfront_public_key.media_signing[0].id]
}
