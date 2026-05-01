
#=======================================================================
# Bootstrap — run once per AWS account, never again.
# Creates S3 bucket and DynamoDB table used by all live/ layers.
#
# Uses LOCAL state intentionally. This is the bootstrapping problem:
# you cannot use remote state to create the infrastructure that
# enables remote state. After applying, store the local state file
# securely (password manager, encrypted storage).
#
# APPLY:
#   cd bootstrap
#   terraform init
#   terraform apply
#=======================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  # No backend block — local state by design
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "tf_state" {
  bucket        = var.state_bucket_name
  force_destroy = false

  tags = {
    Name      = var.state_bucket_name
    ManagedBy = "terraform-bootstrap"
    Purpose   = "terraform-remote-state"
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyNonTLS"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.tf_state.arn,
        "${aws_s3_bucket.tf_state.arn}/*"
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.tf_state]
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  ttl {
    attribute_name = "ExpiresAt"
    enabled        = true
  }

  tags = {
    Name      = var.lock_table_name
    ManagedBy = "terraform-bootstrap"
    Purpose   = "terraform-state-locking"
  }
}
