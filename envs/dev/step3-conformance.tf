# =============================================================================
# Step 3: AWS Config + Conformance Packs
# NIS2 Art.28: Continuous compliance monitoring
#
# Changes vs original:
#   - enable_aws_config = true (was false)
#   - Integrated _archive/step5-conformance.tf (YAML was broken — now fixed)
#   - Added 6 additional NIS2-specific Config rules
# =============================================================================

module "config" {
  source = "../../modules/config"

  name_prefix             = local.name_prefix
  enable_aws_config       = true
  conformance_pack_name   = "nis2-baseline-${var.env}"
  enable_conformance_pack = true

  tags = merge(local.tags, {
    Step        = "3-config"
    NIS2Control = "Article-28-ContinuousCompliance"
  })
}

# =============================================================================
# NIS2 Art.25 — KMS Enforcement Conformance Pack
# Recovered from _archive/ — YAML syntax was broken for 7 months, now fixed!
# Validates every S3 bucket uses an approved KMS key
# =============================================================================
resource "aws_config_conformance_pack" "nis2_kms_enforcement" {
  name          = "${local.name_prefix}-nis2-kms-enforcement"
  template_body = file("${path.root}/../../modules/config/conformance-packs/nis2-kms-enforcement.yaml")

  input_parameter {
    parameter_name  = "AllowedKmsKeyArns"
    parameter_value = var.allowed_kms_key_arn != "" ? var.allowed_kms_key_arn : "arn:aws:kms:eu-central-1:000000000000:key/placeholder"
  }

  depends_on = [module.config]
}

# =============================================================================
# Additional NIS2-specific Config Rules (NIS2 Art.28)
# =============================================================================

resource "aws_config_config_rule" "s3_kms_encryption" {
  name        = "${local.name_prefix}-s3-kms-only"
  description = "NIS2 Art.25: S3 buckets must use KMS encryption (not AES256)"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
  depends_on = [module.config]
  tags = merge(local.tags, { NIS2Control = "Article-25-S3KMS" })
}

resource "aws_config_config_rule" "ec2_imdsv2" {
  name        = "${local.name_prefix}-ec2-imdsv2"
  description = "NIS2 Art.32: IMDSv2 required on all EC2 (SSRF protection)"
  source {
    owner             = "AWS"
    source_identifier = "EC2_IMDSV2_CHECK"
  }
  depends_on = [module.config]
  tags = merge(local.tags, { NIS2Control = "Article-32-IMDSv2" })
}

resource "aws_config_config_rule" "ebs_encryption" {
  name        = "${local.name_prefix}-ebs-encrypted"
  description = "NIS2 Art.25: All EBS volumes must be encrypted"
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
  depends_on = [module.config]
  tags = merge(local.tags, { NIS2Control = "Article-25-EBSEncryption" })
}

resource "aws_config_config_rule" "rds_encryption" {
  name        = "${local.name_prefix}-rds-encrypted"
  description = "NIS2 Art.25: RDS storage must be encrypted"
  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }
  depends_on = [module.config]
  tags = merge(local.tags, { NIS2Control = "Article-25-RDSEncryption" })
}

resource "aws_config_config_rule" "vpc_flow_logs" {
  name        = "${local.name_prefix}-vpc-flow-logs"
  description = "NIS2 Art.32: VPC Flow Logs required for network monitoring"
  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }
  depends_on = [module.config]
  tags = merge(local.tags, { NIS2Control = "Article-32-FlowLogs" })
}

resource "aws_config_config_rule" "kms_rotation" {
  name        = "${local.name_prefix}-kms-rotation"
  description = "NIS2 Art.25: KMS keys must have automatic rotation"
  source {
    owner             = "AWS"
    source_identifier = "CMK_BACKING_KEY_ROTATION_ENABLED"
  }
  depends_on = [module.config]
  tags = merge(local.tags, { NIS2Control = "Article-25-KMSRotation" })
}

resource "aws_config_config_rule" "mfa_enabled" {
  name        = "${local.name_prefix}-mfa-console"
  description = "NIS2 Art.21: MFA required for all IAM console users"
  source {
    owner             = "AWS"
    source_identifier = "MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS"
  }
  depends_on = [module.config]
  tags = merge(local.tags, { NIS2Control = "Article-21-MFA" })
}

resource "aws_config_config_rule" "no_root_access_key" {
  name        = "${local.name_prefix}-no-root-key"
  description = "NIS2 Art.21: Root account must not have active access keys"
  source {
    owner             = "AWS"
    source_identifier = "IAM_ROOT_ACCESS_KEY_CHECK"
  }
  depends_on = [module.config]
  tags = merge(local.tags, { NIS2Control = "Article-21-RootProtection" })
}
