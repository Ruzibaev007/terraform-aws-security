# =============================================================================
# providers.tf — Terraform & AWS provider configuration
# NIS2 Art.28: EU region enforced via default_tags
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

# FIXED: was Owner = "amina", region = "us-east-1"
provider "aws" {
  region = var.region   # eu-central-1 by default (NIS2/GDPR)

  default_tags {
    tags = {
      Owner          = "Protector080322"
      Environment    = var.env
      Project        = var.project
      ManagedBy      = "terraform"
      DataClass      = "Internal"
      Compliance     = "NIS2,DORA,ISO27001"
      DataResidency  = "EU-DE"
      Repository     = "github.com/Protector080322/terraform-aws-security"
    }
  }
}
