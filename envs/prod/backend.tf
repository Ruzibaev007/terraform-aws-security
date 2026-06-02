# =============================================================================
# envs/prod/backend.tf — Production Remote State
# NIS2 Art.25: State encrypted + versioned in EU
# =============================================================================

terraform {
  backend "s3" {
    bucket       = "cybercheck-terraform-state-prod"
    key          = "envs/prod/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
    # kms_key_id = "arn:aws:kms:eu-central-1:ACCOUNT_ID:key/KEY_ID"
  }
}
