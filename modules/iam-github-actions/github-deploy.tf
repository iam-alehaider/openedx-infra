

# ==========================================
# GitHub Actions → Deploy Role (EKS access)
# ==========================================

resource "aws_iam_role" "github_deploy" {
  name = "${local.name}-github-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        # FIX: Multi-claim — repo + environment (tighter than branch-only)
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:environment:${var.environment}"
        }
      }
    }]
  })

  # FIX: Limit role session duration for CI to 1 hour
  max_session_duration = 3600

  tags = local.tags
}

resource "aws_iam_role_policy" "github_deploy" {
  name = "${local.name}-deploy-policy"
  role = aws_iam_role.github_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEKSDescribe"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        # FIX: Scoped to specific cluster ARN — was Resource = "*"
        Resource = "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.eks_cluster_name}"
      },
      {
        # FIX: Explicit deny for cluster mutating actions from deploy role
        Sid    = "DenyEKSMutate"
        Effect = "Deny"
        Action = [
          "eks:DeleteCluster",
          "eks:DeleteNodegroup",
          "eks:CreateCluster"
        ]
        Resource = "*"
      }
    ]
  })
}

