# =============================================================================
# Step 1: Remote State Infrastructure
# S3 bucket + DynamoDB table for Terraform state backend
# NIS2 Art.25: State encrypted, versioned, tamper-proof
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# KMS key for state encryption (NIS2 Art.25)
# =============================================================================
resource "aws_kms_key" "state" {
  description             = "NIS2 Art.25: Terraform state encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(local.tags, {
    Name        = "${local.name_prefix}-state-kms"
    NIS2Control = "Article-25-StateEncryption"
  })
}

resource "aws_kms_alias" "state" {
  name          = "alias/${local.name_prefix}-terraform-state"
  target_key_id = aws_kms_key.state.key_id
}

# =============================================================================
# S3 Bucket: Terraform state
# =============================================================================
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${local.name_prefix}-terraform-state-${data.aws_caller_identity.current.account_id}"
  force_destroy = false   # Never auto-delete state!

  tags = merge(local.tags, {
    Name        = "${local.name_prefix}-terraform-state"
    NIS2Control = "Article-25-StateIntegrity"
    Purpose     = "TerraformState"
  })
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.terraform_state.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureTransport"
        Effect = "Deny"
        Principal = { AWS = "*" }
        Action   = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })
}

# =============================================================================
# DynamoDB: State locking (prevent concurrent applies)
# =============================================================================
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${local.name_prefix}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.state.arn
  }

  point_in_time_recovery { enabled = true }

  tags = merge(local.tags, {
    Name        = "${local.name_prefix}-terraform-locks"
    NIS2Control = "Article-25-StateLocking"
    Purpose     = "TerraformLocks"
  })
}

# =============================================================================
# Outputs
# =============================================================================
output "state_bucket_name" {
  description = "S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_kms_key_arn" {
  description = "KMS key ARN for state encryption"
  value       = aws_kms_key.state.arn
  sensitive   = true
}

output "dynamodb_lock_table" {
  description = "DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.id
}
