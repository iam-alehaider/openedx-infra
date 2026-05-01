

resource "aws_security_group" "rds" {
  name        = "${local.name}-rds-sg"
  description = "RDS MySQL — allow inbound from EKS nodes only on port 3306"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
    description     = "MySQL access from EKS nodes only"
  }

  # FIX: Restrict egress to VPC CIDR only — DB should never initiate internet connections
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow outbound within VPC only"
  }

  tags = merge(local.tags, { Name = "${local.name}-rds-sg" })
}

