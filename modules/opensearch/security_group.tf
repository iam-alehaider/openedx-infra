

resource "aws_security_group" "opensearch" {
  name        = "${local.name}-opensearch-sg"
  description = "OpenSearch — allow HTTPS access from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
    description     = "HTTPS access from EKS nodes"
  }

  # FIX: OpenSearch does not initiate outbound internet connections
  # Restrict egress to VPC CIDR only (was 0.0.0.0/0)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow outbound within VPC only"
  }

  tags = merge(local.tags, { Name = "${local.name}-opensearch-sg" })
}

