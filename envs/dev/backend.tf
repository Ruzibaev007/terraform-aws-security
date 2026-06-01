# =============================================================================
# backend.tf — Remote state configuration
# NIS2 Art.25: State encrypted + versioned in EU region
# =============================================================================

terraform {
  backend "s3" {
    # FIXED: was "us-east-1" — must be EU for NIS2/GDPR data residency
    bucket = "cybercheck-terraform-state"
    key    = "envs/dev/terraform.tfstate"
    region = "eu-central-1"   # Frankfurt — Germany

    # Security: encrypted state + locking
    encrypt      = true
    use_lockfile = true

    # Optional: KMS key for state encryption (NIS2 Art.25)
    # kms_key_id = "arn:aws:kms:eu-central-1:ACCOUNT_ID:key/KEY_ID"
  }
}
