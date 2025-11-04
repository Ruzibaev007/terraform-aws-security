
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

# ------------------ S3 bucket for AWS Config delivery ------------------
resource "aws_s3_bucket" "config_delivery" {
  bucket        = local.cfg_bucket
  force_destroy = true
  tags          = var.tags
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

resource "aws_s3_bucket_server_side_encryption_configuration" "config_delivery" {
  bucket = aws_s3_bucket.config_delivery.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bucket policy per AWS docs (Config delivery channel)
data "aws_iam_policy_document" "config_delivery" {
  statement {
    sid     = "AWSConfigBucketPermissionsCheck"
    effect  = "Allow"
    actions = ["s3:GetBucketAcl"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.config_delivery.bucket}"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:config:${data.aws_region.current.name}:${local.account_id}:*"]
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
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.config_delivery.bucket}"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:config:${data.aws_region.current.name}:${local.account_id}:*"]
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
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.config_delivery.bucket}/${local.cfg_prefix_actual}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:config:${data.aws_region.current.name}:${local.account_id}:*"]
    }
  }
}

resource "aws_s3_bucket_policy" "config_delivery" {
  bucket = aws_s3_bucket.config_delivery.id
  policy = data.aws_iam_policy_document.config_delivery.json
}

# ------------------ S3 bucket for Conformance Pack artifacts ------------------
resource "aws_s3_bucket" "conformance_artifacts" {
  bucket        = local.cpack_bucket
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_ownership_controls" "conformance_artifacts" {
  bucket = aws_s3_bucket.conformance_artifacts.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_public_access_block" "conformance_artifacts" {
  bucket                  = aws_s3_bucket.conformance_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "conformance_artifacts" {
  bucket = aws_s3_bucket.conformance_artifacts.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "conformance_artifacts" {
  bucket = aws_s3_bucket.conformance_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bucket policy per AWS docs (Conformance Packs)

data "aws_iam_policy_document" "conformance_artifacts" {
  statement {
    sid    = "ConformsListArtifactsPrefix"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config-conforms.amazonaws.com"]
    }
    actions   = ["s3:ListBucket"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.conformance_artifacts.bucket}"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:config:${data.aws_region.current.name}:${local.account_id}:*"]
    }
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${local.cpack_prefix}/*"]
    }
  }

  statement {
    sid    = "ConformsReadArtifacts"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config-conforms.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.conformance_artifacts.bucket}/${local.cpack_prefix}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:config:${data.aws_region.current.name}:${local.account_id}:*"]
    }
  }
}

resource "aws_s3_bucket_policy" "conformance_artifacts" {
  bucket = aws_s3_bucket.conformance_artifacts.id
  policy = data.aws_iam_policy_document.conformance_artifacts.json
}


# Recorder
resource "aws_config_configuration_recorder" "this" {
  count    = var.enable_aws_config ? 1 : 0
  name     = "default"
  role_arn = data.aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# Delivery channel
resource "aws_config_delivery_channel" "this" {
  count          = var.enable_aws_config ? 1 : 0
  name           = "default"
  s3_bucket_name = aws_s3_bucket.config_delivery.bucket

  # when count=0 there is no element; when 1, index with [0]
  depends_on = [aws_config_configuration_recorder.this]
}

# Recorder status
resource "aws_config_configuration_recorder_status" "this" {
  count      = var.enable_aws_config ? 1 : 0
  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.this]
}


# ------------------ Conformance Pack ------------------
resource "aws_config_conformance_pack" "starter" {
  count                  = var.enable_conformance_pack ? 1 : 0
  name                   = var.conformance_pack_name
  delivery_s3_bucket     = aws_s3_bucket.conformance_artifacts.bucket
  delivery_s3_key_prefix = local.cpack_prefix
  template_body          = file("${path.module}/conformance-packs/starter.yaml")
  depends_on             = [aws_config_configuration_recorder_status.this]
}
