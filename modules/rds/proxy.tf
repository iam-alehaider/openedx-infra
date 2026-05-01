

resource "aws_db_proxy" "main" {
  count                  = var.proxy_role_arn != "" ? 1 : 0
  name                   = "${local.name}-rds-proxy"
  engine_family          = "MYSQL"
  role_arn               = var.proxy_role_arn
  vpc_subnet_ids         = var.subnet_ids
  vpc_security_group_ids = [aws_security_group.rds.id]

  auth {
    auth_scheme = "SECRETS"
    secret_arn  = aws_db_instance.main.master_user_secret[0].secret_arn
  }
}
