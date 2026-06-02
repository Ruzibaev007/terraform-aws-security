# =============================================================================
# envs/prod/terraform.tfvars — Production Values
# Copy and edit before: terraform apply
# =============================================================================

env     = "prod"
project = "cybercheck"
region  = "eu-central-1"

# Security (all enabled in production)
enable_cloudtrail           = true
enable_security_hub         = true
enable_guardduty            = true
enable_permissions_boundary = true
enable_deny_root_user       = true
enable_require_mfa_iam      = true
enable_aws_config           = true

# Alerts
security_alerts_email = "security@cybercheck-infra.de"

# Tags
cost_center = "security-infra-prod"

# Allowed regions (strict EU for production)
allowed_regions = [
  "eu-central-1",
  "eu-west-1",
  "us-east-1",
]
