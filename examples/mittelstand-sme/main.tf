# =============================================================================
# Example: German Mittelstand SME — Full Production Deployment
# Company: ACME Manufacturing GmbH, Berlin (~500 employees)
# Stack: AWS Multi-Account + NIS2 + GDPR + ISO 27001
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # Remote state — encrypted S3 backend (NIS2 Art.25)
  backend "s3" {
    bucket         = "acme-mfg-terraform-state"
    key            = "prod/multi-account/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "acme-mfg-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# =============================================================================
# LOCAL VALUES
# =============================================================================
locals {
  name_prefix = "${var.name_prefix}-${var.env}"

  # NIS2 Art.28: Asset inventory tags
  common_tags = merge(var.tags, {
    Environment = var.env
    ManagedBy   = "terraform"
    LastUpdated = timestamp()
  })
}

# =============================================================================
# STEP 1: Remote State Backend (NIS2 Art.25 — tamper-proof infrastructure state)
# =============================================================================
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${local.name_prefix}-terraform-state"
  force_destroy = false

  tags = { Purpose = "TerraformState", NIS2Control = "Article-25" }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${local.name_prefix}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = { Purpose = "TerraformLocks" }
}

# =============================================================================
# STEP 2: Logging (NIS2 Art.25 — CloudTrail + KMS)
# =============================================================================
module "logging" {
  source = "../../modules/logging"

  name_prefix       = local.name_prefix
  env               = var.env
  enable_cloudtrail = true
  tags              = local.common_tags
}

# =============================================================================
# STEP 3: IAM Governance (NIS2 Art.21 — MFA + Permission Boundaries)
# =============================================================================
module "permissions_boundary" {
  source = "../../modules/iam/permission-boundary"

  name = "${local.name_prefix}-boundary"
  path = "/"
}

# Security team role (read-only for auditors)
resource "aws_iam_role" "security_auditor" {
  name                 = "${local.name_prefix}-security-auditor"
  permissions_boundary = module.permissions_boundary.permissions_boundary_arn
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action    = "sts:AssumeRole"
      Condition = { Bool = { "aws:MultiFactorAuthPresent" = "true" } }
    }]
  })

  tags = { NIS2Control = "Article-21-RBAC", Role = "Auditor" }
}

resource "aws_iam_role_policy_attachment" "auditor_readonly" {
  role       = aws_iam_role.security_auditor.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# =============================================================================
# STEP 4: Security Services (NIS2 Art.23 — GuardDuty + Security Hub)
# =============================================================================
module "security_services" {
  source = "../../modules/security-services"

  name_prefix               = local.name_prefix
  tags                      = local.common_tags
  enable_security_hub       = var.enable_security_hub
  enable_security_hub_cis   = true
  cis_version               = "1.4.0"
  enable_security_hub_afsbp = true
  afsbp_version             = "1.0.0"
  enable_security_hub_nist  = true
  enable_guardduty                 = var.enable_guardduty
  gd_enable_s3_protection          = true
  gd_enable_eks_audit_logs         = true
  gd_enable_malware_protection_ebs = true
}

# =============================================================================
# STEP 5: AWS Config (NIS2 Art.28 — continuous compliance monitoring)
# =============================================================================
module "config" {
  source = "../../modules/config"

  name_prefix = local.name_prefix
  tags        = local.common_tags
}

# =============================================================================
# STEP 6: Organization SCPs (NIS2 Art.21 + 32 — EU region + MFA)
# =============================================================================
module "organizations" {
  source = "../../modules/organizations"

  ou_names = ["security", "workloads", "sandbox", "infra"]

  # EU data residency (NIS2 Art.28 + GDPR)
  allowed_regions = [
    "eu-central-1",  # Frankfurt — primary
    "eu-west-1",     # Ireland — DR only
    "us-east-1",     # AWS global services (IAM, Route53)
  ]

  enable_deny_root_user            = true
  enable_require_mfa_iam           = true
  enable_protect_security_services = true
}

# =============================================================================
# STEP 7: Backup & Disaster Recovery (NIS2 Art.17)
# =============================================================================
resource "aws_backup_vault" "nis2_dr" {
  name        = "${local.name_prefix}-nis2-backup-vault"
  kms_key_arn = module.logging.kms_key_arn

  tags = { NIS2Control = "Article-17-BusinessContinuity" }
}

resource "aws_backup_plan" "nis2_dr" {
  name = "${local.name_prefix}-nis2-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.nis2_dr.name
    schedule          = "cron(0 2 * * ? *)"  # 02:00 UTC daily

    lifecycle {
      cold_storage_after = 30   # Move to Glacier after 30 days
      delete_after       = 365  # Delete after 1 year
    }

    copy_action {
      destination_vault_arn = "arn:aws:backup:eu-west-1:${data.aws_caller_identity.current.account_id}:backup-vault:cross-region-dr"
      lifecycle {
        delete_after = 365
      }
    }
  }

  tags = { NIS2Control = "Article-17-DataBackup" }
}

resource "aws_backup_selection" "all_tagged_resources" {
  name         = "${local.name_prefix}-backup-selection"
  plan_id      = aws_backup_plan.nis2_dr.id
  iam_role_arn = aws_iam_role.backup.arn

  # Backup all resources tagged with BackupRequired=true
  selection_tag {
    type  = "STRINGEQUALS"
    key   = "BackupRequired"
    value = "true"
  }
}

resource "aws_iam_role" "backup" {
  name = "${local.name_prefix}-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# =============================================================================
# DATA SOURCES & OUTPUTS
# =============================================================================
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

output "account_id"          { value = data.aws_caller_identity.current.account_id }
output "region"              { value = data.aws_region.current.name }
output "kms_key_arn"         { value = module.logging.kms_key_arn }
output "audit_bucket"        { value = module.logging.log_bucket_id }
output "security_auditor_role_arn" { value = aws_iam_role.security_auditor.arn }
output "backup_vault_arn"    { value = aws_backup_vault.nis2_dr.arn }

output "compliance_summary" {
  description = "NIS2/DORA compliance controls deployed"
  value = {
    nis2_article_21 = "MFA enforced, Permission boundaries, RBAC"
    nis2_article_23 = "GuardDuty + Security Hub + Incident Lambda"
    nis2_article_25 = "CloudTrail + KMS + S3 encrypted"
    nis2_article_28 = "EU region restriction SCPs"
    dora_article_16 = "Incident reporting workflow (Step Functions)"
    iso_27001       = "80+ controls mapped — see docs/compliance-mapping.md"
    frameworks      = ["NIS2", "DORA", "ISO27001", "GDPR", "BSI IT-Grundschutz"]
  }
}
