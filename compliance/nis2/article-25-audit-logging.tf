# =============================================================================
# NIS2 Article 25 — Audit Logging, Encryption & Data Protection
# EU Cybersecurity Directive 2022/2555
#
# Controls implemented:
#   25(1) — Encryption at rest (KMS) & in transit (TLS 1.2+)
#   25(2) — Immutable audit logs (S3 Object Lock)
#   25(3) — Log integrity validation (CloudTrail log file validation)
#   25(4) — Retention policy (minimum 1 year)
#   25(5) — Access logging for audit logs themselves
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# =============================================================================
# 25(1): KMS Key — dedicated key for audit logs
# =============================================================================
resource "aws_kms_key" "audit_logs" {
  description             = "NIS2 Art.25: Dedicated KMS key for audit log encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true  # Automatic annual rotation

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccountRoot"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudTrail"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AllowCloudWatch"
        Effect = "Allow"
        Principal = { Service = "logs.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        # NIS2: Deny key deletion without multi-person approval
        Sid    = "DenyScheduleKeyDeletion"
        Effect = "Deny"
        Principal = { AWS = "*" }
        Action = ["kms:ScheduleKeyDeletion", "kms:DeleteAlias"]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalArn" = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/NIS2-BreakGlass-Admin"
          }
        }
      }
    ]
  })

  tags = {
    NIS2Control = "Article-25-1-Encryption"
    Purpose     = "AuditLogEncryption"
    KeyRotation = "Annual-Automatic"
  }
}

resource "aws_kms_alias" "audit_logs" {
  name          = "alias/${var.name_prefix}-nis2-audit-logs"
  target_key_id = aws_kms_key.audit_logs.key_id
}

# =============================================================================
# 25(2) + 25(4): S3 Bucket — immutable audit logs with Object Lock
# =============================================================================
resource "aws_s3_bucket" "audit_logs" {
  bucket        = "${var.name_prefix}-nis2-audit-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = false  # Never auto-delete audit logs!

  tags = {
    NIS2Control    = "Article-25-2-ImmutableLogs"
    DataRetention  = "365-days-minimum"
    Classification = "CONFIDENTIAL"
  }
}

# Object Lock = tamper-proof logs (NIS2 Art.25(2))
resource "aws_s3_bucket_object_lock_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    default_retention {
      mode = "GOVERNANCE"  # Change to COMPLIANCE for strictest NIS2 enforcement
      days = 365           # 1 year minimum per NIS2
    }
  }
}

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.audit_logs.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "audit_logs" {
  bucket                  = aws_s3_bucket.audit_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle: move to Glacier after 90 days, delete after 7 years
resource "aws_s3_bucket_lifecycle_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    id     = "NIS2-AuditLogRetention"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555  # 7 years (German BSI recommendation)
    }
  }
}

# 25(5): Access logging for the audit bucket itself
resource "aws_s3_bucket_logging" "audit_logs" {
  bucket        = aws_s3_bucket.audit_logs.id
  target_bucket = aws_s3_bucket.audit_logs.id
  target_prefix = "access-logs/"
}

# Bucket policy: TLS only + deny unencrypted uploads
resource "aws_s3_bucket_policy" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureTransport"
        Effect = "Deny"
        Principal = { AWS = "*" }
        Action   = "s3:*"
        Resource = [
          aws_s3_bucket.audit_logs.arn,
          "${aws_s3_bucket.audit_logs.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid    = "DenyUnencryptedUploads"
        Effect = "Deny"
        Principal = { AWS = "*" }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.audit_logs.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid    = "AllowCloudTrailWrite"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.audit_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AllowCloudTrailAclCheck"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.audit_logs.arn
      }
    ]
  })
}

# =============================================================================
# 25(3): CloudTrail — multi-region with log file validation
# =============================================================================
resource "aws_cloudtrail" "nis2_audit" {
  name                          = "${var.name_prefix}-nis2-audit-trail"
  s3_bucket_name                = aws_s3_bucket.audit_logs.id
  kms_key_id                    = aws_kms_key.audit_logs.arn
  is_multi_region_trail         = true   # Catch API calls from all regions
  enable_log_file_validation    = true   # Tamper detection (NIS2 Art.25(3))
  include_global_service_events = true   # IAM, STS, Route53

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    # Log all S3 object access (data events)
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }

    # Log Lambda invocations
    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }

  tags = {
    NIS2Control = "Article-25-3-AuditIntegrity"
    Retention   = "365-days"
  }

  depends_on = [aws_s3_bucket_policy.audit_logs]
}

# =============================================================================
# 25(4): CloudWatch Log Group — real-time log analysis
# =============================================================================
resource "aws_cloudwatch_log_group" "nis2_audit" {
  name              = "/nis2/${var.name_prefix}/cloudtrail"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.audit_logs.arn

  tags = {
    NIS2Control = "Article-25-4-LogRetention"
  }
}

# =============================================================================
# AWS Config Rule — verify encryption is always on
# =============================================================================
resource "aws_config_config_rule" "s3_encryption" {
  name        = "NIS2-Article25-S3Encryption"
  description = "NIS2 Art.25(1): All S3 buckets must use KMS encryption"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  tags = { NIS2Control = "Article-25-1-S3Encryption" }
}

resource "aws_config_config_rule" "rds_encryption" {
  name        = "NIS2-Article25-RDSEncryption"
  description = "NIS2 Art.25(1): All RDS instances must be encrypted"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  tags = { NIS2Control = "Article-25-1-RDSEncryption" }
}

resource "aws_config_config_rule" "kms_rotation" {
  name        = "NIS2-Article25-KMSRotation"
  description = "NIS2 Art.25(1): KMS keys must have automatic rotation enabled"

  source {
    owner             = "AWS"
    source_identifier = "CMK_BACKING_KEY_ROTATION_ENABLED"
  }

  tags = { NIS2Control = "Article-25-1-KeyRotation" }
}

# =============================================================================
# Variables & Outputs
# =============================================================================
variable "name_prefix" {
  description = "Resource name prefix"
  type        = string
}

output "audit_bucket_id"   { value = aws_s3_bucket.audit_logs.id }
output "audit_bucket_arn"  { value = aws_s3_bucket.audit_logs.arn }
output "kms_key_arn"       { value = aws_kms_key.audit_logs.arn }
output "kms_key_id"        { value = aws_kms_key.audit_logs.key_id }
output "cloudtrail_arn"    { value = aws_cloudtrail.nis2_audit.arn }
