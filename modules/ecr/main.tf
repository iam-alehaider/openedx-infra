
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_ecr_repository" "main" {
  for_each = toset(var.repositories)

  # FIX: Use var.project prefix instead of hardcoded "openedx/" — makes module reusable
  name                 = "${var.project}/${each.key}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    # FIX: Use customer-managed KMS key (was using AWS default key)
    kms_key         = aws_kms_key.ecr.arn
  }

  tags = merge(local.tags, { Name = "${var.project}/${each.key}" })
}

# Lifecycle policy: expire untagged quickly, keep last N tagged images
resource "aws_ecr_lifecycle_policy" "main" {
  for_each   = aws_ecr_repository.main
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep last ${var.image_retention_count} tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = var.image_tag_prefixes
          countType     = "imageCountMoreThan"
          countNumber   = var.image_retention_count
        }
        action = { type = "expire" }
      }
    ]
  })
}

# FIX: Restrict repo policy to specific IAM roles (EKS node role + GitHub CI role)
# Was: Principal = root account = ANY IAM user/role in account could pull
resource "aws_ecr_repository_policy" "main" {
  for_each   = aws_ecr_repository.main
  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEKSNodePull"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_pull_role_arns
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid    = "AllowCIPush"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_push_role_arns
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
      }
    ]
  })
}

