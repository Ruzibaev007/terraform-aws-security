# =============================================================================
# modules/macie/main.tf — Amazon Macie
# GDPR Art.5 & Art.32: Discover and protect sensitive personal data
# NIS2 Art.25: Data classification and encryption
# =============================================================================

# Enable Macie (GDPR personal data discovery)
resource "aws_macie2_account" "this" {
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  status                       = "ENABLED"
}

# Custom data identifier: German personal data patterns
resource "aws_macie2_custom_data_identifier" "german_id" {
  name        = "${var.name_prefix}-german-id-number"
  description = "GDPR: Detect German ID numbers (Personalausweis)"
  regex       = "[A-Z0-9]{9}"

  keywords            = ["Personalausweis", "Ausweisnummer", "ID-Nummer"]
  maximum_match_distance = 50
  ignore_words        = []

  tags = merge(var.tags, { GDPRControl = "Art5-DataMinimization" })
}

resource "aws_macie2_custom_data_identifier" "iban_de" {
  name        = "${var.name_prefix}-german-iban"
  description = "GDPR/DORA: Detect German IBAN numbers"
  regex       = "DE[0-9]{2}\\s?[0-9]{4}\\s?[0-9]{4}\\s?[0-9]{4}\\s?[0-9]{4}\\s?[0-9]{2}"

  keywords     = ["IBAN", "Kontonummer", "Bankverbindung"]
  ignore_words = []

  tags = merge(var.tags, { GDPRControl = "Art9-FinancialData" })
}

# Macie findings published to Security Hub (NIS2 Art.23)
resource "aws_macie2_findings_filter" "critical_pii" {
  name        = "${var.name_prefix}-critical-pii"
  description = "Filter for critical PII findings requiring immediate action"
  action      = "ARCHIVE"

  finding_criteria {
    criterion {
      field  = "severity.description"
      values = ["HIGH", "CRITICAL"]
    }
  }

  tags = merge(var.tags, { GDPRControl = "Art5-DataProtection" })
}

# S3 bucket for Macie findings export (NIS2 Art.25 — audit trail)
resource "aws_s3_bucket" "macie_findings" {
  bucket        = "${var.name_prefix}-macie-findings-${var.account_id}"
  force_destroy = false

  tags = merge(var.tags, {
    GDPRControl = "Art5-DataInventory"
    NIS2Control = "Article-25-FindingsAudit"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "macie_findings" {
  bucket = aws_s3_bucket.macie_findings.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "macie_findings" {
  bucket                  = aws_s3_bucket.macie_findings.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

variable "name_prefix"  { type = string }
variable "account_id"   { type = string }
variable "kms_key_arn"  { type = string }
variable "tags"         { type = map(string); default = {} }

output "macie_findings_bucket" { value = aws_s3_bucket.macie_findings.id }
