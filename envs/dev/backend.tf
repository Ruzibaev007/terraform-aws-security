terraform {
  backend "s3" {
    bucket       = "example-tf-state"
    key          = "envs/dev/terraform.tfstate"
    region       = "us-east-1"
    profile      = "dev"
    use_lockfile = true
    encrypt      = true
    # kms_key_id omitted or redacted for public safety
  }
}
