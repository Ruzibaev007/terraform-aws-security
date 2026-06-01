# =============================================================================
# Example: Healthcare — GDPR + NIS2 (Essential Operator)
# Scenario: Private clinic network, 3 locations, Berlin/Hamburg/München
# Patient records: ~50,000 patients, GDPR Art.9 (special category data)
# NIS2: Essential operator (health sector)
# =============================================================================

env         = "prod"
name_prefix = "medicare-clinic"
aws_region  = "eu-central-1"  # Frankfurt — mandatory for healthcare data (GDPR)

# NIS2 essential operator — ALL security features mandatory
enable_cloudtrail           = true
enable_security_hub         = true
enable_guardduty            = true
enable_permissions_boundary = true
enable_deny_root_user       = true
enable_require_mfa_iam      = true

# Strict EU-only regions (GDPR Art.44 — no data transfer outside EU)
allowed_regions = [
  "eu-central-1",  # Frankfurt — primary
  "eu-west-1",     # Ireland — DR only (still EU)
]

# Security contacts
security_alerts_email = "ciso@medicareclinic.de"
ciso_email            = "ciso@medicareclinic.de"
security_team_email   = "security@medicareclinic.de"

# Disaster Recovery (NIS2 Art.17 — critical for healthcare)
disaster_recovery = {
  rto_hours = 1    # 1 hour RTO — patient records must be available
  rpo_hours = 0.25 # 15 min RPO — no data loss acceptable
  backup_retention_days       = 2555  # 7 years (German medical records law)
  cross_region_backup_enabled = true
  backup_region               = "eu-west-1"
}

tags = {
  Organization       = "MediCare-Clinic-GmbH"
  Environment        = "production"
  Owner              = "IT-Security"
  CostCenter         = "IT-001"
  Compliance         = "NIS2,GDPR,HIPAA-equivalent,ISO27001"
  DataClassification = "CONFIDENTIAL"  # Patient data = special category
  DataResidency      = "EU-DE"
  GDPR_Article9      = "true"          # Special category health data
  NIS2_Operator_Type = "essential"
  BackupRequired     = "true"
  RetentionYears     = "7"
  ManagedBy          = "terraform"
}
