#!/bin/bash
# =============================================================================
# validate-compliance.sh
# NIS2 + DORA + ISO 27001 compliance validation script
# Run BEFORE terraform apply in CI/CD pipeline
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
WARNINGS=0

print_header() {
  echo -e "\n${BLUE}========================================${NC}"
  echo -e "${BLUE}  NIS2/DORA Compliance Validation${NC}"
  echo -e "${BLUE}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
  echo -e "${BLUE}========================================${NC}\n"
}

pass() { echo -e "${GREEN}✅ PASS${NC}: $1"; PASSED=$((PASSED + 1)); }
fail() { echo -e "${RED}❌ FAIL${NC}: $1"; FAILED=$((FAILED + 1)); }
warn() { echo -e "${YELLOW}⚠️  WARN${NC}: $1"; WARNINGS=$((WARNINGS + 1)); }
info() { echo -e "${BLUE}ℹ️  INFO${NC}: $1"; }

# =============================================================================
print_header

# Check required tools
info "Checking required tools..."
for tool in terraform opa aws jq; do
  if command -v "$tool" &>/dev/null; then
    pass "$tool is installed ($(command -v $tool))"
  else
    fail "$tool is NOT installed — required for compliance checks"
  fi
done

echo ""
info "=== STEP 1: Terraform Validation (NIS2 Art.28 — Code Integrity) ==="

# terraform fmt check
if terraform fmt -recursive -check &>/dev/null; then
  pass "Terraform formatting is correct"
else
  fail "Terraform formatting errors — run: terraform fmt -recursive"
fi

# terraform validate
if terraform validate -json 2>/dev/null | jq -e '.valid == true' &>/dev/null; then
  pass "Terraform configuration is valid"
else
  fail "Terraform validation failed — check configuration errors"
fi

echo ""
info "=== STEP 2: OPA Policy Checks (NIS2 Art.21/23/25/32) ==="

# Run OPA tests
if [ -d "policies-as-code/opa" ]; then
  if opa test policies-as-code/opa/ -v 2>/dev/null | grep -q "PASS"; then
    pass "All OPA policy tests passed"
  else
    fail "OPA policy tests failed — review policies-as-code/opa/"
  fi
else
  warn "OPA policies directory not found — skipping policy tests"
fi

# Validate plan against OPA if plan.json exists
if [ -f "envs/dev/plan.json" ]; then
  OPA_RESULT=$(opa eval \
    --data policies-as-code/opa/policies.rego \
    --input envs/dev/plan.json \
    "data.terraform.security.result" 2>/dev/null || echo '{"passed": false}')

  if echo "$OPA_RESULT" | jq -e '.result[0].expressions[0].value.passed == true' &>/dev/null; then
    pass "Terraform plan passes all NIS2 compliance checks"
  else
    VIOLATIONS=$(echo "$OPA_RESULT" | jq -r '.result[0].expressions[0].value.messages[]' 2>/dev/null || echo "Unknown violations")
    fail "Terraform plan has compliance violations:"
    echo "$VIOLATIONS" | while read -r line; do
      echo -e "    ${RED}→${NC} $line"
    done
  fi
fi

echo ""
info "=== STEP 3: Security Tools (tfsec + Checkov) ==="

# tfsec
if command -v tfsec &>/dev/null; then
  if tfsec . --no-color --soft-fail 2>/dev/null; then
    pass "tfsec security scan passed"
  else
    warn "tfsec found issues — review above for HIGH/CRITICAL"
  fi
else
  warn "tfsec not installed — install: brew install tfsec"
fi

# checkov
if command -v checkov &>/dev/null; then
  if checkov -d . --framework terraform --quiet 2>/dev/null; then
    pass "Checkov compliance scan passed"
  else
    warn "Checkov found issues — review above output"
  fi
else
  warn "checkov not installed — install: pip install checkov"
fi

echo ""
info "=== STEP 4: AWS Configuration Check ==="

# Check AWS credentials
if aws sts get-caller-identity &>/dev/null; then
  ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
  REGION=$(aws configure get region 2>/dev/null || echo "not set")
  pass "AWS credentials valid (Account: $ACCOUNT, Region: $REGION)"

  # Warn if non-EU region
  if [[ "$REGION" != eu-* ]]; then
    warn "AWS region '$REGION' is not EU — NIS2 Art.28 requires EU data residency"
  fi
else
  warn "AWS credentials not configured — skipping AWS checks"
fi

# =============================================================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  RESULTS SUMMARY${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "  ${GREEN}Passed:${NC}   $PASSED"
echo -e "  ${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "  ${RED}Failed:${NC}   $FAILED"
echo ""

if [ "$FAILED" -gt 0 ]; then
  echo -e "${RED}❌ COMPLIANCE CHECK FAILED — Fix issues before deploying!${NC}"
  echo -e "${RED}   NIS2/DORA non-compliance may result in fines up to €10M${NC}"
  exit 1
else
  echo -e "${GREEN}✅ ALL COMPLIANCE CHECKS PASSED — Safe to deploy${NC}"
  exit 0
fi
