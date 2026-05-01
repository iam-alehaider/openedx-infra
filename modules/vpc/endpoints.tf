

# modules/vpc/endpoints.tf

resource "aws_security_group" "endpoints" {
  name   = "${var.project}-${var.environment}-vpce-sg"
  vpc_id = aws_vpc.main.id        # was: aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = local.tags
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id        # was: aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id
  tags              = local.tags
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = aws_vpc.main.id       # was: aws_vpc.this.id
  service_name       = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags               = local.tags
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = aws_vpc.main.id       # was: aws_vpc.this.id
  service_name       = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags               = local.tags
}

resource "aws_vpc_endpoint" "secrets" {
  vpc_id             = aws_vpc.main.id       # was: aws_vpc.this.id
  service_name       = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags               = local.tags
}
