# =============================================================================
# modules/config/main.tf — AWS Config Module
# NIS2 Art.28: Continuous compliance monitoring
# FIXED: sse_algorithm = "AES256" → "aws:kms" (stronger encryption)
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}
data "aws_iam_role" "config" {
  name = "AWSServiceRoleForConfig"
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  cfg_bucket   = var.config_delivery_bucket_name != "" ? var.config_delivery_bucket_name : "${var.name_prefix}-config-delivery-${local.account_id}-${local.region}"
  cpack_bucket = var.conformance_artifacts_bucket_name != "" ? var.conformance_artifacts_bucket_name : "awsconfigconforms-${var.name_prefix}-${local.account_id}-${local.region}"

  cfg_prefix_actual = "AWSLogs/${local.account_id}/Config"
  cpack_prefix      = "artifacts"
}

# =============================================================================
# KMS Key for Config encryption (NIS2 Art.25)
# =============================================================================
resource "aws_kms_key" "config" {
  description             = "NIS2 Art.25: KMS key for AWS Config delivery bucket"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-config-kms"
    NIS2Control = "Article-25-ConfigEncryption"
  })
}

resource "aws_kms_alias" "config" {
  name          = "alias/${var.name_prefix}-config"
  target_key_id = aws_kms_key.config.key_id
}

# =============================================================================
# S3 bucket for AWS Config delivery
# FIXED: sse_algorithm = "AES256" → "aws:kms"
# =============================================================================
resource "aws_s3_bucket" "config_delivery" {
  bucket        = local.cfg_bucket
  force_destroy = false   # FIXED: was true — never auto-delete Config records!
  tags          = merge(var.tags, { NIS2Control = "Article-28-ConfigDelivery" })
}

resource "aws_s3_bucket_ownership_controls" "config_delivery" {
  bucket = aws_s3_bucket.config_delivery.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_public_access_block" "config_delivery" {
  bucket                  = aws_s3_bucket.config_delivery.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "config_delivery" {
  bucket = aws_s3_bucket.config_delivery.id
  versioning_configuration { status = "Enabled" }
}

# FIXED: was AES256 — must use KMS for NIS2 Art.25 compliance
resource "aws_s3_bucket_server_side_encryption_configuration" "config_delivery" {
  bucket = aws_s3_bucket.config_delivery.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"          # FIXED: was "AES256"
      kms_master_key_id = aws_kms_key.config.arn
    }
    bucket_key_enabled = true
  }
}

# S3 lifecycle: move old Config snapshots to Glacier (cost + retention)
resource "aws_s3_bucket_lifecycle_configuration" "config_delivery" {
  bucket = aws_s3_bucket.config_delivery.id

  rule {
    id     = "NIS2-ConfigRetention"
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
      days = 2555  # 7 years — German BSI recommendation
    }
  }
}

# Bucket policy for Config delivery
data "aws_iam_policy_document" "config_delivery" {
  statement {
    sid     = "AWSConfigBucketPermissionsCheck"
    effect  = "Allow"
    actions = ["s3:GetBucketAcl"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    resources  = [aws_s3_bucket.config_delivery.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }

  statement {
    sid     = "AWSConfigBucketExistenceCheck"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    resources = [aws_s3_bucket.config_delivery.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }

  statement {
    sid     = "AWSConfigBucketDelivery"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    resources = ["${aws_s3_bucket.config_delivery.arn}/${local.cfg_prefix_actual}/AWSLogs/${local.account_id}/Config/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.config_delivery.arn, "${aws_s3_bucket.config_delivery.arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "config_delivery" {
  bucket = aws_s3_bucket.config_delivery.id
  policy = data.aws_iam_policy_document.config_delivery.json
}

# =============================================================================
# AWS Config Recorder & Delivery Channel
# =============================================================================
resource "aws_config_configuration_recorder" "this" {
  count    = var.enable_aws_config ? 1 : 0
  name     = "${var.name_prefix}-config-recorder"
  role_arn = data.aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  count          = var.enable_aws_config ? 1 : 0
  name           = "${var.name_prefix}-config-channel"
  s3_bucket_name = aws_s3_bucket.config_delivery.id
  s3_key_prefix  = local.cfg_prefix_actual

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  count      = var.enable_aws_config ? 1 : 0
  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.this]
}

# =============================================================================
# Outputs
# =============================================================================
output "config_bucket_id"  { value = aws_s3_bucket.config_delivery.id }
output "config_bucket_arn" { value = aws_s3_bucket.config_delivery.arn }
output "config_kms_key_arn" { value = aws_kms_key.config.arn }
