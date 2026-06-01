#!/bin/bash
# =============================================================================
# install/macos.sh — Setup for macOS (Intel + Apple Silicon)
# terraform-aws-security by Protector080322
# Tested on: macOS 13 Ventura, 14 Sonoma, 15 Sequoia
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
pass() { echo -e "${GREEN}✅${NC} $1"; }
info() { echo -e "${BLUE}ℹ️${NC}  $1"; }
warn() { echo -e "${YELLOW}⚠️${NC}  $1"; }
fail() { echo -e "${RED}❌${NC} $1"; exit 1; }

echo -e "${BLUE}"
echo "================================================"
echo "  terraform-aws-security — macOS Setup"
echo "  github.com/Protector080322/terraform-aws-security"
echo "================================================${NC}"

# =============================================================================
# 1. Homebrew
# =============================================================================
info "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Apple Silicon path
  if [[ $(uname -m) == "arm64" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi
pass "Homebrew ready: $(brew --version | head -1)"

# =============================================================================
# 2. Core tools
# =============================================================================
info "Installing core tools..."
TOOLS=(terraform awscli jq git gh python3)
for tool in "${TOOLS[@]}"; do
  if brew list "$tool" &>/dev/null; then
    pass "$tool already installed"
  else
    info "Installing $tool..."
    brew install "$tool"
    pass "$tool installed"
  fi
done

# =============================================================================
# 3. Security & Compliance tools
# =============================================================================
info "Installing security tools..."

# tfsec
if ! command -v tfsec &>/dev/null; then
  brew install tfsec
fi
pass "tfsec: $(tfsec --version 2>/dev/null | head -1)"

# checkov
if ! command -v checkov &>/dev/null; then
  pip3 install checkov --quiet
fi
pass "checkov: $(checkov --version 2>/dev/null)"

# OPA (Open Policy Agent)
if ! command -v opa &>/dev/null; then
  brew install opa
fi
pass "OPA: $(opa version 2>/dev/null | head -1)"

# gitleaks (secrets scanning — NIS2 Art.25)
if ! command -v gitleaks &>/dev/null; then
  brew install gitleaks
fi
pass "gitleaks: $(gitleaks version 2>/dev/null)"

# infracost (cost estimation)
if ! command -v infracost &>/dev/null; then
  brew install infracost
  warn "Run 'infracost auth login' to enable cost scanning"
fi
pass "infracost: $(infracost --version 2>/dev/null | head -1)"

# pre-commit
if ! command -v pre-commit &>/dev/null; then
  brew install pre-commit
fi
pass "pre-commit: $(pre-commit --version 2>/dev/null)"

# kubectl (for Kubernetes module)
if ! command -v kubectl &>/dev/null; then
  brew install kubectl
fi
pass "kubectl: $(kubectl version --client --short 2>/dev/null | head -1)"

# =============================================================================
# 4. Terraform version manager (tfenv)
# =============================================================================
info "Installing tfenv (Terraform version manager)..."
if ! command -v tfenv &>/dev/null; then
  brew install tfenv
  tfenv install 1.9.0
  tfenv use 1.9.0
fi
pass "tfenv: $(tfenv --version 2>/dev/null)"

# =============================================================================
# 5. AWS CLI configuration check
# =============================================================================
info "Checking AWS CLI..."
if aws sts get-caller-identity &>/dev/null; then
  ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
  REGION=$(aws configure get region 2>/dev/null || echo "NOT SET")
  pass "AWS configured (Account: $ACCOUNT, Region: $REGION)"
  if [[ "$REGION" != eu-* ]]; then
    warn "AWS region '$REGION' is not EU — set eu-central-1 for NIS2/GDPR compliance"
    echo "  Run: aws configure set region eu-central-1"
  fi
else
  warn "AWS not configured. Run: aws configure"
  echo "  Required: Access Key ID, Secret Key, Region=eu-central-1"
fi

# =============================================================================
# 6. Repository setup
# =============================================================================
info "Setting up repository..."

# Install pre-commit hooks
if [ -f ".pre-commit-config.yaml" ]; then
  pre-commit install
  pass "pre-commit hooks installed"
fi

# Make scripts executable
chmod +x scripts/*.sh 2>/dev/null || true

# =============================================================================
# 7. Verify all tools
# =============================================================================
echo ""
echo -e "${BLUE}================================================"
echo "  Verification Summary"
echo "================================================${NC}"

TOOLS_CHECK=(terraform aws jq git gh opa tfsec checkov gitleaks kubectl pre-commit)
ALL_OK=true
for tool in "${TOOLS_CHECK[@]}"; do
  if command -v "$tool" &>/dev/null; then
    pass "$tool ✅"
  else
    warn "$tool — NOT found"
    ALL_OK=false
  fi
done

echo ""
if $ALL_OK; then
  echo -e "${GREEN}✅ All tools installed! Run: make validate${NC}"
else
  echo -e "${YELLOW}⚠️  Some tools missing. Re-run this script.${NC}"
fi

echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. aws configure                  # Set AWS credentials"
echo "  2. make validate                  # Run compliance check"
echo "  3. cd envs/dev && terraform init  # Initialize Terraform"
echo "  4. terraform plan                 # Preview changes"
