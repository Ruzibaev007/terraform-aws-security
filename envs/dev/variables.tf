# =============================================================================
# variables.tf — All input variables
# =============================================================================

variable "env" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be one of: dev, staging, prod"
  }
}

variable "project" {
  type        = string
  description = "Project name prefix for all resources"
  default     = "cybercheck"
}

variable "cost_center" {
  type        = string
  description = "Cost center tag for billing"
  default     = "security-infra"
}

# FIXED: was "us-east-1" — NIS2/GDPR requires EU data residency
variable "region" {
  description = "AWS region (EU required for NIS2/GDPR compliance)"
  type        = string
  default     = "eu-central-1"   # Frankfurt — Germany

  validation {
    condition     = startswith(var.region, "eu-")
    error_message = "NIS2 Art.28: region must be EU (eu-*) for data residency compliance"
  }
}

# FIXED: was false — Security Hub must be enabled for NIS2 Art.23
variable "enable_security_hub" {
  type        = bool
  default     = true   # NIS2 Art.23: mandatory for essential operators
  description = "Enable AWS Security Hub (NIS2 Art.23 — centralized findings)"
}

# FIXED: was false — GuardDuty must be enabled for NIS2 Art.23
variable "enable_guardduty" {
  type        = bool
  default     = true   # NIS2 Art.23: mandatory threat detection
  description = "Enable AWS GuardDuty (NIS2 Art.23 — threat detection)"
}

variable "enable_aws_config" {
  type        = bool
  default     = true   # NIS2 Art.28: continuous compliance monitoring
  description = "Enable AWS Config (NIS2 Art.28 — configuration compliance)"
}

variable "enable_cloudtrail" {
  type        = bool
  default     = true   # NIS2 Art.25: audit logging mandatory
  description = "Enable CloudTrail (NIS2 Art.25 — audit logging)"
}

variable "enable_permissions_boundary" {
  type        = bool
  default     = true   # NIS2 Art.21: privilege control
  description = "Attach permissions boundary to all IAM roles/users"
}

variable "enable_deny_root_user" {
  type        = bool
  default     = true   # NIS2 Art.21: root must be protected
  description = "SCP: deny root account usage (NIS2 Art.21)"
}

variable "enable_require_mfa_iam" {
  type        = bool
  default     = true   # NIS2 Art.21: MFA mandatory
  description = "SCP: require MFA for all IAM operations (NIS2 Art.21)"
}

variable "allowed_kms_key_arn" {
  description = "KMS key ARN for encryption (NIS2 Art.25)"
  type        = string
  default     = ""
}

variable "security_alerts_email" {
  description = "Email for security alerts (NIS2 Art.23 incident notification)"
  type        = string
  default     = ""
}

variable "allowed_regions" {
  description = "Allowed AWS regions (NIS2 Art.28 — EU data residency)"
  type        = list(string)
  default     = ["eu-central-1", "eu-west-1", "us-east-1"]
}
