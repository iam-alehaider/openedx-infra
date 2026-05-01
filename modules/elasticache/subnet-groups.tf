

resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.name}-redis-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = local.tags
}

