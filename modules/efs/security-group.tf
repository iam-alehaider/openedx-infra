
resource "aws_security_group" "efs" {
  name        = "${local.name}-efs-sg"
  description = "EFS — allow NFS from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
    description     = "NFS from EKS nodes"
  }

  # FIX: EFS does not initiate outbound connections — restrict to VPC CIDR only
  # (Previous: 0.0.0.0/0 egress was unnecessary and violated zero-trust model)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow outbound within VPC only"
  }

  tags = merge(local.tags, { Name = "${local.name}-efs-sg" })
}

