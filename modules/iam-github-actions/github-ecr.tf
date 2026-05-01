
# ==========================================
# GitHub Actions → ECR Push Role
# ==========================================

resource "aws_iam_role" "github_ecr_push" {
  name = "${local.name}-github-ecr-push"

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
        # FIX: Multi-claim validation — repo + branch (was only repo:ref which is weaker)
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_main_branch}"
        }
      }
    }]
  })

  # FIX: Limit role session duration for CI to 1 hour
  max_session_duration = 3600

  tags = local.tags
}

resource "aws_iam_role_policy" "github_ecr_push" {
  name = "${local.name}-ecr-push-policy"
  role = aws_iam_role.github_ecr_push.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowECRAuth"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "AllowECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        # FIX: Scoped to specific repositories only — was openedx/* wildcard
        Resource = [
          for repo in var.ecr_repository_names :
          "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.project}/${repo}"
        ]
      },
      {
        # FIX: Explicit deny for destructive ECR operations from CI
        Sid    = "DenyECRDelete"
        Effect = "Deny"
        Action = [
          "ecr:DeleteRepository",
          "ecr:DeleteRepositoryPolicy",
          "ecr:BatchDeleteImage"
        ]
        Resource = "*"
      }
    ]
  })
}

