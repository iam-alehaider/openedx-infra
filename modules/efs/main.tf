
resource "aws_kms_key" "efs" {
  description             = "EFS encryption key for ${local.name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = merge(local.tags, { Name = "${local.name}-efs-kms" })
}

resource "aws_efs_file_system" "main" {
  creation_token   = "${local.name}-efs"
  encrypted        = true
  kms_key_id       = aws_kms_key.efs.arn
  performance_mode = "generalPurpose"
  # FIX: Use elastic throughput for production workloads — bursting is unpredictable
  # under sustained OpenEdX LMS workloads and causes credit exhaustion
  throughput_mode  = var.throughput_mode

  # FIX: Removed conflicting dual lifecycle policy that caused storage churn:
  # "move to IA after 30 days" + "move back immediately after 1 access"
  # = files constantly moving between tiers = cost spikes
  # Now: only transition TO IA; removal from IA is handled by access pattern naturally
  lifecycle_policy {
    transition_to_ia = var.transition_to_ia
  }

  tags = merge(local.tags, { Name = "${local.name}-efs" })

  # FIX: Prevent accidental destruction of file system
  lifecycle {
    prevent_destroy = true
  }
}

# EFS Resource Policy — enforce TLS mounting and restrict access to VPC

resource "aws_efs_file_system_policy" "main" {
  file_system_id = aws_efs_file_system.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforceTLS"
        Effect = "Deny"
        Principal = "*"
        Action    = "elasticfilesystem:*"
        Resource  = aws_efs_file_system.main.arn
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid    = "AllowVPCAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_role_arns
        }
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource  = aws_efs_file_system.main.arn
        Condition = {
          StringEquals = { "aws:SourceVpc" = var.vpc_id }
        }
      }
    ]
  })
}


# One mount target per AZ
resource "aws_efs_mount_target" "main" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

# FIX: Parameterized UID/GID — hardcoded 1000 breaks when container user IDs differ
# Align with your Kubernetes pod security context
resource "aws_efs_access_point" "openedx" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/openedx"
    creation_info {
      owner_gid   = var.openedx_gid
      owner_uid   = var.openedx_uid
      permissions = var.access_point_permissions
    }
  }

  posix_user {
    gid = var.openedx_gid
    uid = var.openedx_uid
  }

  tags = merge(local.tags, { Name = "${local.name}-efs-ap-openedx" })
}






