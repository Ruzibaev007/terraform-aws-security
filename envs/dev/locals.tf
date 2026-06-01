# =============================================================================
# locals.tf — Core configuration
# Project: terraform-aws-security
# Owner: Protector080322 (CyberCheck Infrastructure)
# =============================================================================

locals {
  name_prefix = "${var.project}-${var.env}"

  tags = {
    Project        = var.project
    Env            = var.env
    Owner          = "Protector080322"
    ManagedBy      = "terraform"
    Repository     = "github.com/Protector080322/terraform-aws-security"
    Compliance     = "NIS2,DORA,ISO27001"
    DataResidency  = "EU-DE"
    CostCenter     = var.cost_center
  }
}
