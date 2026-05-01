

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  oidc_provider     = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
  oidc_provider_arn = aws_iam_openid_connect_provider.eks.arn
}


#==============================
#─── IRSA: EBS CSI Driver ───
#==============================


resource "aws_iam_role" "ebs_csi" {
  name = "${local.name}-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi.name
}


#=================================
#─── IRSA: EFS CSI Driver ───
#=================================


resource "aws_iam_role" "efs_csi" {
  name = "${local.name}-efs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider}:sub" = "system:serviceaccount:kube-system:efs-csi-controller-sa"
        }
      }
    }]
  })
  tags = local.tags
}

resource "aws_iam_policy" "efs_csi" {
  name = "${local.name}-efs-csi-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets",
          "ec2:DescribeAvailabilityZones"
        ]
        # FIX: Describe-level actions require "*", cannot be scoped to specific resource
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["elasticfilesystem:CreateAccessPoint"]
        Resource = "*"
        Condition = {
          StringLike = { "aws:RequestTag/efs.csi.aws.com/cluster" = "true" }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["elasticfilesystem:DeleteAccessPoint"]
        Resource = "*"
        Condition = {
          StringEquals = { "aws:ResourceTag/efs.csi.aws.com/cluster" = "true" }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs_csi" {
  policy_arn = aws_iam_policy.efs_csi.arn
  role       = aws_iam_role.efs_csi.name
}

#====================================
#─── IRSA: Cluster Autoscaler ───
#====================================


resource "aws_iam_role" "cluster_autoscaler" {
  name = "${local.name}-cluster-autoscaler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
        }
      }
    }]
  })
  tags = local.tags
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name = "${local.name}-cluster-autoscaler-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeImages",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
  role       = aws_iam_role.cluster_autoscaler.name
}

#==================================
#─── IRSA: OpenEdX S3 Access ───
#==================================


resource "aws_iam_role" "openedx_s3" {
  name = "${local.name}-openedx-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider}:sub" = "system:serviceaccount:openedx:openedx-sa"
        }
      }
    }]
  })
  tags = local.tags
}

resource "aws_iam_policy" "openedx_s3" {
  name = "${local.name}-openedx-s3-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket", "s3:GetBucketLocation"]
      # FIX: Scoped to specific bucket name pattern matching platform-storage module
      Resource = [
        "arn:aws:s3:::${local.name}-openedx-storage",
        "arn:aws:s3:::${local.name}-openedx-storage/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "openedx_s3" {
  policy_arn = aws_iam_policy.openedx_s3.arn
  role       = aws_iam_role.openedx_s3.name
}

