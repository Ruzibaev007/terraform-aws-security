# =============================================================================
# Step 3: AWS Config — Continuous Compliance Monitoring
# NIS2 Art.28: Configuration compliance must be continuously monitored
# FIXED: enable_aws_config = true (was false)
# =============================================================================

module "config" {
  source = "../../modules/config"

  name_prefix             = local.name_prefix
  enable_aws_config       = true   # FIXED: was false — Config was disabled!
  conformance_pack_name   = "nis2-baseline-${var.env}"
  enable_conformance_pack = true

  tags = merge(local.tags, { Step = "3-config", NIS2Control = "Article-28" })
}

# =============================================================================
# NIS2 Art.28 — Additional Config Rules (beyond conformance pack)
# =============================================================================

# Rule: Ensure S3 buckets use KMS (not AES256)
resource "aws_config_config_rule" "s3_kms_encryption" {
  name        = "${local.name_prefix}-s3-kms-encryption"
  description = "NIS2 Art.25: S3 buckets must use KMS (not AES256)"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = [module.config]
  tags       = merge(local.tags, { NIS2Control = "Article-25-KMSEncryption" })
}

# Rule: EC2 instances must use IMDSv2
resource "aws_config_config_rule" "ec2_imdsv2" {
  name        = "${local.name_prefix}-ec2-imdsv2-required"
  description = "NIS2 Art.32: IMDSv2 required to prevent SSRF"

  source {
    owner             = "AWS"
    source_identifier = "EC2_IMDSV2_CHECK"
  }

  depends_on = [module.config]
  tags       = merge(local.tags, { NIS2Control = "Article-32-IMDSv2" })
}

# Rule: EBS volumes must be encrypted
resource "aws_config_config_rule" "ebs_encryption" {
  name        = "${local.name_prefix}-ebs-encryption"
  description = "NIS2 Art.25: All EBS volumes must be encrypted"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [module.config]
  tags       = merge(local.tags, { NIS2Control = "Article-25-EBSEncryption" })
}

# Rule: RDS instances must be encrypted
resource "aws_config_config_rule" "rds_encryption" {
  name        = "${local.name_prefix}-rds-encryption"
  description = "NIS2 Art.25: RDS storage must be encrypted"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [module.config]
  tags       = merge(local.tags, { NIS2Control = "Article-25-RDSEncryption" })
}

# Rule: VPC flow logs must be enabled (NIS2 Art.32)
resource "aws_config_config_rule" "vpc_flow_logs" {
  name        = "${local.name_prefix}-vpc-flow-logs"
  description = "NIS2 Art.32: VPC flow logs required for network monitoring"

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  depends_on = [module.config]
  tags       = merge(local.tags, { NIS2Control = "Article-32-NetworkMonitoring" })
}

# Rule: Lambda functions must be in VPC (NIS2 Art.32 — network isolation)
resource "aws_config_config_rule" "lambda_in_vpc" {
  name        = "${local.name_prefix}-lambda-in-vpc"
  description = "NIS2 Art.32: Lambda functions should be VPC-isolated"

  source {
    owner             = "AWS"
    source_identifier = "LAMBDA_INSIDE_VPC"
  }

  depends_on = [module.config]
  tags       = merge(local.tags, { NIS2Control = "Article-32-NetworkIsolation" })
}
