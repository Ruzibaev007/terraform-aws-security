# =============================================================================
# Example: German Mittelstand SME
# Company: Manufacturing company, ~500 employees, Berlin
# Compliance: NIS2 (essential operator) + GDPR + ISO 27001
# =============================================================================

# --- Core settings ---
env         = "prod"
name_prefix = "acme-mfg"
aws_region  = "eu-central-1"   # Frankfurt — EU data residency (NIS2 Art.28)

# --- Security features (NIS2 mandatory for essential operators) ---
enable_cloudtrail          = true
enable_security_hub        = true
enable_guardduty           = true
enable_permissions_boundary = true

# --- Security alerts email ---
security_alerts_email = "security-team@acme-manufacturing.de"

# --- NIS2 Article 21: Access Control ---
enable_deny_root_user  = true
enable_require_mfa_iam = true
allowed_regions = [
  "eu-central-1",  # Frankfurt (primary)
  "eu-west-1",     # Ireland (DR failover)
  "us-east-1",     # AWS global services only
]

# --- Tags (NIS2 Article 28: asset inventory) ---
tags = {
  Organization       = "ACME-Manufacturing-GmbH"
  Environment        = "production"
  Owner              = "IT-Infrastructure"
  CostCenter         = "CC-0042"
  Compliance         = "NIS2,GDPR,ISO27001"
  DataClassification = "INTERNAL"
  DataResidency      = "EU-DE"
  BackupRequired     = "true"
  ManagedBy          = "terraform"
}
