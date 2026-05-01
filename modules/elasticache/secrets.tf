

data "aws_secretsmanager_secret_version" "redis" {
  secret_id = var.redis_secret_arn
}
