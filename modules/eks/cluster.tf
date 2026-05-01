
#===============================================
# KMS Key for EKS Secrets Encryption
#===============================================

resource "aws_kms_key" "eks" {
  description             = "EKS secrets encryption for ${local.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = merge(local.tags, { Name = "${local.name}-eks-kms" })
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${local.name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

#===============================================
# CloudWatch Log Group for EKS Control Plane
# FIX: Added explicit log group with retention (was defaulting to never-expire)
#===============================================

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_days
  tags              = local.tags
}

#==============================
# EKS Cluster IAM Role
#==============================

resource "aws_iam_role" "cluster" {
  name = "${local.name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

#=====================================
# Cluster Security Group
#=====================================

resource "aws_security_group" "cluster" {
  name        = "${local.name}-eks-cluster-sg"
  description = "EKS cluster communication security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS to nodes and VPC endpoints within VPC"
  }

  egress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Kubelet API on nodes"
  }

  tags = merge(local.tags, { Name = "${local.name}-eks-cluster-sg" })
}


resource "aws_security_group_rule" "cluster_ingress_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nodes.id
  security_group_id        = aws_security_group.cluster.id
  description              = "Allow nodes to communicate with cluster API"
}

# FIX: Allow admin kubectl access from specified CIDRs (explicit rule, not relying on public_access_cidrs alone)
resource "aws_security_group_rule" "cluster_ingress_admin" {
  count             = length(var.cluster_endpoint_public_cidrs) > 0 && var.cluster_endpoint_public_access ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.cluster_endpoint_public_cidrs
  security_group_id = aws_security_group.cluster.id
  description       = "Allow admin kubectl access from approved CIDRs"
}

#============================
# EKS Cluster
#============================

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_cidrs
  }

  encryption_config {
    provider { key_arn = aws_kms_key.eks.arn }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = var.cluster_log_types

  tags       = merge(local.tags, { Name = var.cluster_name })
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_cloudwatch_log_group.eks,
  ]
}

#================================
# OIDC Provider for IRSA
#================================

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  tags            = local.tags
}












