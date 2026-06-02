# =============================================================================
# envs/prod/main.tf — Production Environment
# Mirror of dev with stricter settings + Backup/DR
# NIS2 Art.21, 23, 25, 28 — all controls active
# =============================================================================

locals {
  name_prefix = "${var.project}-prod"
  tags = {
    Environment = "production"
    Owner       = "Protector080322"
    Project     = var.project
    ManagedBy   = "terraform"
    Compliance  = "NIS2,DORA,ISO27001"
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ─── Step 1: IAM Permissions Boundary ────────────────────────────────────────
module "permissions_boundary" {
  count  = var.enable_permissions_boundary ? 1 : 0
  source = "../../modules/iam/permission-boundary"
  name   = "${local.name_prefix}-boundary"
  path   = "/"
}

# ─── Step 2: Logging (NIS2 Art.25) ───────────────────────────────────────────
module "logging" {
  source            = "../../modules/logging"
  name_prefix       = local.name_prefix
  env               = var.env
  enable_cloudtrail = var.enable_cloudtrail
  tags              = local.tags
}

# ─── Step 3: AWS Config (NIS2 Art.28) ────────────────────────────────────────
module "config" {
  source                  = "../../modules/config"
  name_prefix             = local.name_prefix
  enable_aws_config       = var.enable_aws_config
  conformance_pack_name   = "nis2-prod"
  enable_conformance_pack = true
  tags                    = local.tags
}

# ─── Step 4: Security Services (NIS2 Art.23) ─────────────────────────────────
module "security_services" {
  source                           = "../../modules/security-services"
  name_prefix                      = local.name_prefix
  tags                             = local.tags
  enable_security_hub              = var.enable_security_hub
  enable_security_hub_cis          = true
  cis_version                      = "1.4.0"
  enable_security_hub_afsbp        = true
  afsbp_version                    = "1.0.0"
  enable_security_hub_nist         = true
  enable_guardduty                 = var.enable_guardduty
  gd_enable_s3_protection          = true
  gd_enable_eks_audit_logs         = true
  gd_enable_malware_protection_ebs = true
}

# ─── Step 5: SCPs (NIS2 Art.21 + Art.32) ─────────────────────────────────────
module "organizations" {
  source                           = "../../modules/organizations"
  ou_names                         = ["security", "workloads", "sandbox", "infra"]
  allowed_regions                  = var.allowed_regions
  attach_to_ous                    = false
  enable_deny_root_user            = var.enable_deny_root_user
  enable_require_mfa_iam           = var.enable_require_mfa_iam
  enable_protect_security_services = true
}

# ─── Step 6: Backup/DR (NIS2 Art.17) ─────────────────────────────────────────
resource "aws_backup_vault" "prod" {
  name        = "${local.name_prefix}-backup"
  kms_key_arn = module.logging.kms_key_arn
  tags        = merge(local.tags, { NIS2Control = "Article-17-DR" })
}

resource "aws_backup_plan" "prod" {
  name = "${local.name_prefix}-backup-plan"

  rule {
    rule_name         = "hourly-prod"
    target_vault_name = aws_backup_vault.prod.name
    schedule          = "cron(0 * * * ? *)"
    lifecycle {
      cold_storage_after = 30
      delete_after       = 2555
    }
  }
}

resource "aws_iam_role" "backup" {
  name = "${local.name_prefix}-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow"; Principal = { Service = "backup.amazonaws.com" }; Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# ─── Outputs ──────────────────────────────────────────────────────────────────
output "account_id"   { value = data.aws_caller_identity.current.account_id }
output "region"       { value = data.aws_region.current.name }
output "environment"  { value = "production" }
output "backup_vault" { value = aws_backup_vault.prod.arn }
