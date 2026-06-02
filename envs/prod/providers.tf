# =============================================================================
# envs/prod/providers.tf — Production Provider
# NIS2 Art.28: EU region enforced
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

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Owner         = "Protector080322"
      Environment   = "production"
      Project       = var.project
      ManagedBy     = "terraform"
      Compliance    = "NIS2,DORA,ISO27001"
      DataResidency = "EU-DE"
      Repository    = "github.com/Protector080322/terraform-aws-security"
    }
  }
}
