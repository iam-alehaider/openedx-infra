resource "aws_s3_bucket" "openedx_storage" {
  bucket        = "${local.name}-openedx-storage"
  force_destroy = var.environment != "prod"
  tags          = merge(local.tags, { Name = "${local.name}-openedx-storage" })
}

# FIX: Enforce BucketOwnerEnforced — eliminates legacy ACL edge cases
resource "aws_s3_bucket_ownership_controls" "openedx_storage" {
  bucket = aws_s3_bucket.openedx_storage.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "openedx_storage" {
  bucket = aws_s3_bucket.openedx_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "openedx_storage" {
  bucket = aws_s3_bucket.openedx_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      # FIX: Use dedicated app-storage KMS key (was sharing single key with tf state)
      kms_master_key_id = aws_kms_key.app_storage.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "openedx_storage" {
  bucket                  = aws_s3_bucket.openedx_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "openedx_storage" {
  bucket = aws_s3_bucket.openedx_storage.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    # FIX: Restrict to specific origins — was ["*"] which allows any domain to
    # make cross-origin requests (upload abuse, data exfiltration vector)
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "openedx_storage" {
  bucket = aws_s3_bucket.openedx_storage.id

  # FIX: Abort incomplete multipart uploads after 7 days
  # Prevents silent storage cost growth from stuck uploads
  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
  }
}

