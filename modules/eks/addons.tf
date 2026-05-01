



resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  addon_version               = var.addon_versions["kube_proxy"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  tags                        = merge(local.tags, { Name = "${local.name}-kube-proxy" })
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  addon_version               = var.addon_versions["vpc_cni"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  tags                        = merge(local.tags, { Name = "${local.name}-vpc-cni" })
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  addon_version               = var.addon_versions["coredns"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  tags                        = merge(local.tags, { Name = "${local.name}-coredns" })
  depends_on                  = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = var.addon_versions["ebs_csi"]
  service_account_role_arn    = aws_iam_role.ebs_csi.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  tags                        = merge(local.tags, { Name = "${local.name}-ebs-csi" })
  depends_on                  = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "efs_csi" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-efs-csi-driver"
  addon_version               = var.addon_versions["efs_csi"]
  service_account_role_arn    = aws_iam_role.efs_csi.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  tags                        = merge(local.tags, { Name = "${local.name}-efs-csi" })
  depends_on                  = [aws_eks_node_group.main]
}

