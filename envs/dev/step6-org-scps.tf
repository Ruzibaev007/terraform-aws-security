# =============================================================================
# Step 6: Organization Service Control Policies (SCPs)
# NIS2 Article 21 (Access Control) + Article 32 (Network/Region Restriction)
#
# FIXES applied:
#   - allowed_regions changed from us-east-1 → EU regions
#   - enable_deny_root_user = true  (was false — critical gap)
#   - enable_require_mfa_iam = true (was false — NIS2 Article 21 violation)
# =============================================================================

module "organizations" {
  source = "../../modules/organizations"

  ou_names = ["security", "workloads", "sandbox", "infra"]

  # FIXED: EU data residency — Frankfurt primary, Ireland fallback
  # NIS2 Article 28: Data must stay in EU
  allowed_regions = [
    "eu-central-1",   # Frankfurt — primary (Germany)
    "eu-west-1",      # Ireland — DR failover
    "eu-north-1",     # Stockholm — optional
    "us-east-1",      # Required for global AWS services (IAM, Route53, etc.)
  ]

  attach_to_ous = false

  # FIXED: NIS2 Article 21(3) — Root account must be protected
  enable_deny_root_user = true     # was false — critical security gap!

  # FIXED: NIS2 Article 21(1) — MFA must be enforced
  enable_require_mfa_iam = true    # was false — NIS2 violation!

  # Keep existing protections
  enable_protect_security_services = true
}

# =============================================================================
# NIS2-specific SCPs (additional to module defaults)
# =============================================================================

# SCP: Deny disabling CloudTrail (NIS2 Article 25 — audit logs must be preserved)
resource "aws_organizations_policy" "deny_disable_cloudtrail" {
  name        = "NIS2-DenyDisableCloudTrail"
  description = "NIS2 Art.25: Prevents disabling or deleting CloudTrail audit logs"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyCloudTrailModification"
        Effect = "Deny"
        Action = [
          "cloudtrail:DeleteTrail",
          "cloudtrail:StopLogging",
          "cloudtrail:UpdateTrail",
          "cloudtrail:PutEventSelectors",
          "cloudtrail:DeleteEventDataStore"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    NIS2Control = "Article-25-AuditIntegrity"
  }
}

# SCP: Deny disabling GuardDuty (NIS2 Article 23 — incident detection must stay on)
resource "aws_organizations_policy" "deny_disable_guardduty" {
  name        = "NIS2-DenyDisableGuardDuty"
  description = "NIS2 Art.23: Prevents disabling threat detection"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyGuardDutyDisable"
        Effect = "Deny"
        Action = [
          "guardduty:DeleteDetector",
          "guardduty:DisassociateFromMasterAccount",
          "guardduty:DisassociateMembers",
          "guardduty:StopMonitoringMembers"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    NIS2Control = "Article-23-ThreatDetection"
  }
}

# SCP: Deny disabling Security Hub (NIS2 Article 23 — centralized findings)
resource "aws_organizations_policy" "deny_disable_securityhub" {
  name        = "NIS2-DenyDisableSecurityHub"
  description = "NIS2 Art.23: Prevents disabling centralized security findings"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenySecurityHubDisable"
        Effect = "Deny"
        Action = [
          "securityhub:DisableSecurityHub",
          "securityhub:DeleteHub",
          "securityhub:DisassociateFromMasterAccount"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    NIS2Control = "Article-23-CentralizedMonitoring"
  }
}

# SCP: Deny S3 public access (NIS2 Article 32 — network security)
resource "aws_organizations_policy" "deny_s3_public_access" {
  name        = "NIS2-DenyS3PublicAccess"
  description = "NIS2 Art.32: Prevents making S3 buckets publicly accessible"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyS3PublicAccess"
        Effect = "Deny"
        Action = [
          "s3:PutBucketPublicAccessBlock",
          "s3:DeletePublicAccessBlock"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "s3:PublicAccessBlockConfiguration/BlockPublicAcls"       = "false"
            "s3:PublicAccessBlockConfiguration/BlockPublicPolicy"     = "false"
            "s3:PublicAccessBlockConfiguration/IgnorePublicAcls"      = "false"
            "s3:PublicAccessBlockConfiguration/RestrictPublicBuckets" = "false"
          }
        }
      }
    ]
  })

  tags = {
    NIS2Control = "Article-32-NetworkSecurity"
  }
}

# =============================================================================
# Attach all SCPs to Organization Root
# =============================================================================

variable "policies_to_attach" {
  type = set(string)
  default = [
    "ProtectSecurityServices",
    "RestrictRegions",
    "DenyLeaveOrg",
    "NIS2-DenyDisableCloudTrail",
    "NIS2-DenyDisableGuardDuty",
    "NIS2-DenyDisableSecurityHub",
    "NIS2-DenyS3PublicAccess",
  ]
}

variable "already_attached_policy_names" {
  type    = set(string)
  default = []
}

locals {
  created_policy_names = toset(keys(module.organizations.policy_ids))
  desired_names        = length(var.policies_to_attach) > 0 ? var.policies_to_attach : local.created_policy_names
  attach_names         = length(var.already_attached_policy_names) > 0 ? toset(setsubtract(local.desired_names, var.already_attached_policy_names)) : local.desired_names
}

resource "aws_organizations_policy_attachment" "root" {
  for_each  = local.attach_names
  policy_id = module.organizations.policy_ids[each.key]
  target_id = module.organizations.root_id
}
