variable "env" {
  type        = string
  description = "Environment name (e.g., dev, prod)"
  default     = "dev"
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "enable_security_hub" {
  type    = bool
  default = false
}

variable "enable_guardduty" {
  type    = bool
  default = false
}

variable "allowed_kms_key_arn" {
  description = "KMS key ARN allowed for encryption (kept private)"
  type        = string
}
