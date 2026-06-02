# =============================================================================
# envs/prod/variables.tf — Production variables
# =============================================================================

variable "env" {
  type    = string
  default = "prod"
}

variable "project" {
  type    = string
  default = "cybercheck"
}

variable "cost_center" {
  type    = string
  default = "security-infra-prod"
}

variable "region" {
  type    = string
  default = "eu-central-1"
  validation {
    condition     = startswith(var.region, "eu-")
    error_message = "NIS2 Art.28: region must be EU (eu-*)"
  }
}

variable "enable_security_hub"         { type = bool; default = true }
variable "enable_guardduty"            { type = bool; default = true }
variable "enable_aws_config"           { type = bool; default = true }
variable "enable_cloudtrail"           { type = bool; default = true }
variable "enable_permissions_boundary" { type = bool; default = true }
variable "enable_deny_root_user"       { type = bool; default = true }
variable "enable_require_mfa_iam"      { type = bool; default = true }

variable "security_alerts_email" {
  type    = string
  default = ""
}

variable "allowed_kms_key_arn" {
  type    = string
  default = ""
}

variable "allowed_regions" {
  type    = list(string)
  default = ["eu-central-1", "eu-west-1", "us-east-1"]
}
