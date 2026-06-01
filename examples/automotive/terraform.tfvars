# =============================================================================
# Example: Automotive — VDA/TISAX + NIS2 (Important Operator)
# Scenario: Tier-1 automotive supplier, Stuttgart
# Products: ECU firmware, ADAS software for BMW/Mercedes
# Compliance: TISAX, ISO/SAE 21434, NIS2 (important operator), ISO 27001
# =============================================================================

env         = "prod"
name_prefix = "autotech-supplier"
aws_region  = "eu-central-1"  # Frankfurt — VDA requires EU data residency

enable_cloudtrail           = true
enable_security_hub         = true
enable_guardduty            = true
enable_permissions_boundary = true
enable_deny_root_user       = true
enable_require_mfa_iam      = true

# EU + limited US for OEM connectivity (BMW, Mercedes partner systems)
allowed_regions = [
  "eu-central-1",  # Frankfurt — primary
  "eu-west-1",     # Ireland — DR failover
  "us-east-1",     # AWS global services only
]

security_alerts_email = "security@autotech-supplier.de"
ciso_email            = "ciso@autotech-supplier.de"
security_team_email   = "soc@autotech-supplier.de"

# IP Allowlist for OEM connections (BMW, Mercedes, Volkswagen)
oem_partner_cidrs = [
  "10.100.0.0/16",  # BMW partner network (example)
  "10.200.0.0/16",  # Mercedes partner network (example)
]

# Disaster Recovery
disaster_recovery = {
  rto_hours                   = 4
  rpo_hours                   = 1
  backup_retention_days       = 365
  cross_region_backup_enabled = true
  backup_region               = "eu-west-1"
}

tags = {
  Organization       = "AutoTech-Supplier-GmbH"
  Environment        = "production"
  Owner              = "IT-Security"
  CostCenter         = "RD-042"
  Compliance         = "TISAX,NIS2,ISO27001,ISO-SAE-21434"
  DataClassification = "RESTRICTED"   # OEM IP and ECU firmware
  DataResidency      = "EU-DE"
  TISAX_Label        = "HIGH"
  NIS2_Operator_Type = "important"
  VDA_ISA_Version    = "6.0"
  BackupRequired     = "true"
  ManagedBy          = "terraform"
}
