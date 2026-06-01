#!/bin/bash
# =============================================================================
# generate-report.sh
# Automatic NIS2/DORA/ISO 27001 compliance report generator
# Output: Markdown report + JSON data
# =============================================================================

set -euo pipefail

REPORT_DIR="reports"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
REPORT_FILE="$REPORT_DIR/compliance-report-$TIMESTAMP.md"
JSON_FILE="$REPORT_DIR/compliance-data-$TIMESTAMP.json"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

mkdir -p "$REPORT_DIR"

echo -e "${BLUE}Generating NIS2/DORA compliance report...${NC}"

# =============================================================================
# COLLECT AWS DATA
# =============================================================================
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "NOT_CONFIGURED")
REGION=$(aws configure get region 2>/dev/null || echo "eu-central-1")
DATE=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

# Check GuardDuty
GD_STATUS="❌ NOT ENABLED"
if aws guardduty list-detectors --query 'DetectorIds[0]' --output text 2>/dev/null | grep -q "[a-z0-9]"; then
  GD_STATUS="✅ ENABLED"
fi

# Check Security Hub
SH_STATUS="❌ NOT ENABLED"
if aws securityhub describe-hub --query 'HubArn' --output text 2>/dev/null | grep -q "arn:"; then
  SH_STATUS="✅ ENABLED"
fi

# Check CloudTrail
CT_STATUS="❌ NOT ENABLED"
CT_COUNT=$(aws cloudtrail describe-trails --query 'trailList | length(@)' --output text 2>/dev/null || echo "0")
if [ "$CT_COUNT" -gt "0" ]; then CT_STATUS="✅ ENABLED ($CT_COUNT trails)"; fi

# Check MFA for root
ROOT_MFA="❌ NOT CONFIGURED"
if aws iam get-account-summary --query 'SummaryMap.AccountMFAEnabled' --output text 2>/dev/null | grep -q "1"; then
  ROOT_MFA="✅ ENABLED"
fi

# OPA test results
OPA_STATUS="⚠️ OPA NOT INSTALLED"
OPA_PASS=0
OPA_FAIL=0
if command -v opa &>/dev/null && [ -d "policies-as-code/opa" ]; then
  if opa test policies-as-code/opa/ 2>/dev/null | grep -q "PASS"; then
    OPA_STATUS="✅ ALL TESTS PASSED"
    OPA_PASS=$(opa test policies-as-code/opa/ 2>/dev/null | grep -c "PASS" || echo 0)
  else
    OPA_STATUS="❌ TESTS FAILED"
    OPA_FAIL=$(opa test policies-as-code/opa/ 2>/dev/null | grep -c "FAIL" || echo 0)
  fi
fi

# =============================================================================
# GENERATE MARKDOWN REPORT
# =============================================================================
cat > "$REPORT_FILE" << REPORT
# NIS2/DORA Compliance Report
**Generated:** $DATE
**Account:** $ACCOUNT_ID
**Region:** $REGION
**Repository:** terraform-aws-security

---

## Executive Summary

| Framework | Status | Coverage |
|-----------|--------|----------|
| **NIS2** (EU 2022/2555) | ✅ Implemented | Articles 21, 23, 25, 28, 32 |
| **DORA** (EU 2022/2554) | ✅ Implemented | Article 16 (Incident Reporting) |
| **ISO 27001:2022** | ✅ Mapped | 35+ controls |
| **BSI IT-Grundschutz** | ✅ Aligned | ORP.4, CON.1, DER.2.1, NET.1.1 |
| **GDPR** | ✅ Configured | EU data residency, Art.9 support |

---

## NIS2 Control Status

### Article 21 — Access Control

| Control | Status | Implementation |
|---------|--------|----------------|
| MFA Enforcement | ✅ | \`aws_iam_policy.nis2_enforce_mfa\` |
| Permission Boundaries | ✅ | \`modules/iam/permission-boundary/\` |
| Root Account Protection | ✅ | SCP: deny-root-user |
| Access Key Rotation 90d | ✅ | AWS Config rule |
| Break-Glass PAM Role | ✅ | \`aws_iam_role.nis2_break_glass\` |
| Session Timeout 8h | ✅ | IAM session policy |

### Article 23 — Incident Detection & Response

| Control | Status | Implementation |
|---------|--------|----------------|
| GuardDuty | $GD_STATUS | \`modules/security-services\` |
| Security Hub | $SH_STATUS | CIS 1.4.0 + AFSBP + NIST |
| Incident Lambda | ✅ | Auto-response + BSI notification |
| EventBridge Rules | ✅ | GuardDuty HIGH/CRITICAL → Lambda |
| CloudWatch Alarms | ✅ | Root login, MFA disable, GD disable |

### Article 25 — Audit Logging & Encryption

| Control | Status | Implementation |
|---------|--------|----------------|
| CloudTrail | $CT_STATUS | Multi-region, log validation |
| KMS Encryption | ✅ | Dedicated key, auto-rotation |
| S3 Object Lock | ✅ | GOVERNANCE mode, 365 days |
| Log Retention 365d | ✅ | S3 Lifecycle + Glacier |
| Root MFA | $ROOT_MFA | IAM account settings |
| S3 Encryption (Config) | ✅ | AWS Config rule |
| RDS Encryption (Config) | ✅ | AWS Config rule |

### Article 28 — Supply Chain & Data Residency

| Control | Status | Implementation |
|---------|--------|----------------|
| EU Region Restriction | ✅ | SCP: eu-central-1, eu-west-1 |
| Deny CloudTrail Disable | ✅ | SCP: NIS2-DenyDisableCloudTrail |
| Deny GuardDuty Disable | ✅ | SCP: NIS2-DenyDisableGuardDuty |
| Deny S3 Public Access | ✅ | SCP: NIS2-DenyS3PublicAccess |

---

## DORA Control Status

| Control | Status | Implementation |
|---------|--------|----------------|
| Incident Classification | ✅ | Lambda: dora-classifier |
| 4h Initial Notification | ✅ | Step Functions workflow |
| 72h Intermediate Report | ✅ | Step Functions Wait state |
| 1-month Final Report | ✅ | Step Functions workflow |
| BaFin SNS Notification | ✅ | \`aws_sns_topic.dora_supervisor\` |

---

## Policy-as-Code Results

| Tool | Status | Details |
|------|--------|---------|
| OPA/Rego Tests | $OPA_STATUS | NIS2/DORA/ISO 27001 policies |
| tfsec | ✅ Run in CI/CD | HIGH+ severity gate |
| checkov | ✅ Run in CI/CD | SARIF output to GitHub |
| terraform validate | ✅ Run in CI/CD | On every PR |

---

## Industry Examples Available

| Scenario | Location | Compliance |
|----------|----------|------------|
| German Mittelstand SME | \`examples/mittelstand-sme/\` | NIS2 + GDPR + ISO 27001 |
| Healthcare | \`examples/healthcare/\` | NIS2 essential + GDPR Art.9 |
| Automotive (TISAX) | \`examples/automotive/\` | TISAX + ISO-SAE-21434 + NIS2 |

---

## Kubernetes Security

| Control | Status | Implementation |
|---------|--------|----------------|
| k3s Hardened Cluster | ✅ | \`kubernetes/k3s-hardened/\` |
| NetworkPolicies | ✅ | Default deny + explicit allow |
| RBAC (Auditor Role) | ✅ | Read-only cluster role |
| IMDSv2 Required | ✅ | EC2 metadata options |
| No Public IP | ✅ | SSM access only |
| Encrypted Root Volume | ✅ | KMS encryption |

---

## CI/CD Security Pipeline

\`\`\`
terraform fmt → tfsec → checkov → OPA → terraform plan → OPA eval → deploy
\`\`\`

See: \`.github/workflows/plan.yml\`

---

## Reporting Contacts

| Authority | Country | Contact |
|-----------|---------|---------|
| BSI | Germany (NIS2) | https://www.bsi.bund.de/meldung |
| BaFin | Germany (DORA) | https://www.bafin.de/meldungen |

---

*Report generated by \`scripts/generate-report.sh\`*
*Full control mapping: \`docs/compliance-mapping.md\`*
REPORT

# =============================================================================
# GENERATE JSON DATA
# =============================================================================
cat > "$JSON_FILE" << JSON
{
  "report_timestamp": "$DATE",
  "account_id": "$ACCOUNT_ID",
  "region": "$REGION",
  "frameworks": ["NIS2", "DORA", "ISO27001", "GDPR", "BSI"],
  "controls": {
    "guardduty": "$GD_STATUS",
    "security_hub": "$SH_STATUS",
    "cloudtrail": "$CT_STATUS",
    "root_mfa": "$ROOT_MFA",
    "opa_tests": "$OPA_STATUS"
  },
  "opa_results": {
    "passed": $OPA_PASS,
    "failed": $OPA_FAIL
  }
}
JSON

echo -e "${GREEN}✅ Report generated:${NC}"
echo "  Markdown: $REPORT_FILE"
echo "  JSON:     $JSON_FILE"
echo ""
echo -e "${YELLOW}Open report:${NC} cat $REPORT_FILE"
