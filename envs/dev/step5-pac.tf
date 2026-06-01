# =============================================================================
# Step 5: Policy-as-Code (PAC) — OPA/Rego Compliance Validation
# NIS2 Art.28: All infrastructure changes must be policy-validated
#
# HOW IT WORKS:
#   1. CI/CD runs: terraform plan -out=tfplan
#   2. CI/CD runs: terraform show -json tfplan > plan.json
#   3. CI/CD runs: opa eval --data policies-as-code/opa/policies.rego \
#                           --input envs/dev/plan.json \
#                           "data.terraform.security.result"
#   4. If result.passed = false → pipeline BLOCKS deployment
#
# LOCAL USAGE:
#   make validate-opa    # via Makefile
#   ./scripts/validate-compliance.sh
# =============================================================================

# =============================================================================
# Makefile targets (saved as local-exec for documentation)
# =============================================================================
resource "null_resource" "pac_documentation" {
  triggers = { always = timestamp() }

  provisioner "local-exec" {
    command = <<-SH
      echo "=== NIS2 Policy-as-Code Status ==="
      echo "OPA policies: policies-as-code/opa/"
      echo "OPA tests:    policies-as-code/opa/policies_test.rego"
      echo ""
      echo "Run compliance check:"
      echo "  ./scripts/validate-compliance.sh"
      echo ""
      echo "Run OPA tests only:"
      echo "  opa test policies-as-code/opa/ -v"
    SH

    interpreter = ["bash", "-c"]
  }

  lifecycle { ignore_changes = [triggers] }
}

# =============================================================================
# SSM Parameter: Store OPA policy version for audit trail
# NIS2 Art.28: Policy changes must be traceable
# =============================================================================
resource "aws_ssm_parameter" "pac_version" {
  name        = "/${local.name_prefix}/pac/opa-policy-version"
  type        = "String"
  value       = "2.0.0"
  description = "NIS2 Art.28: Current OPA policy version (auto-updated by CI/CD)"

  tags = merge(local.tags, {
    NIS2Control = "Article-28-PolicyAsCode"
    UpdatedBy   = "CI/CD"
  })
}

resource "aws_ssm_parameter" "pac_frameworks" {
  name  = "/${local.name_prefix}/pac/frameworks-covered"
  type  = "StringList"
  value = "NIS2,DORA,ISO27001,BSI-IT-Grundschutz"

  tags = merge(local.tags, { NIS2Control = "Article-28-ComplianceFrameworks" })
}

# =============================================================================
# EventBridge: Alert when OPA policy files are modified in CodeCommit/S3
# NIS2 Art.28: Policy changes require notification
# =============================================================================
resource "aws_cloudwatch_event_rule" "policy_file_changed" {
  name        = "${local.name_prefix}-opa-policy-changed"
  description = "NIS2 Art.28: Alert when OPA compliance policies are modified"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created", "Object Deleted"]
    detail = {
      bucket = {
        name = ["${local.name_prefix}-terraform-state"]
      }
      object = {
        key = [{ prefix = "policies-as-code/" }]
      }
    }
  })

  tags = merge(local.tags, { NIS2Control = "Article-28-PolicyChangeDetection" })
}

# =============================================================================
# Outputs: OPA integration info for CI/CD
# =============================================================================
output "pac_opa_command" {
  description = "Command to run OPA compliance check"
  value       = "opa eval --data policies-as-code/opa/policies.rego --input envs/dev/plan.json 'data.terraform.security.result'"
}

output "pac_validate_command" {
  description = "Full compliance validation script"
  value       = "./scripts/validate-compliance.sh"
}

output "pac_frameworks" {
  description = "Compliance frameworks covered by PAC"
  value       = ["NIS2", "DORA", "ISO 27001", "BSI IT-Grundschutz"]
}
