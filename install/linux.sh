#!/bin/bash
# =============================================================================
# install/linux.sh — Setup for Linux (Ubuntu 20+, Debian 11+, Linux Mint 21+)
# terraform-aws-security by Protector080322
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
pass() { echo -e "${GREEN}✅${NC} $1"; }
info() { echo -e "${BLUE}ℹ️${NC}  $1"; }
warn() { echo -e "${YELLOW}⚠️${NC}  $1"; }

# Detect distro
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO="$ID"
  DISTRO_VERSION="$VERSION_ID"
else
  DISTRO="unknown"
fi

echo -e "${BLUE}"
echo "================================================"
echo "  terraform-aws-security — Linux Setup"
echo "  Detected: $DISTRO $DISTRO_VERSION"
echo "================================================${NC}"

# =============================================================================
# 1. System update
# =============================================================================
info "Updating system packages..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
  curl wget unzip git jq python3 python3-pip \
  gnupg software-properties-common lsb-release \
  ca-certificates apt-transport-https

pass "System packages updated"

# =============================================================================
# 2. Terraform (HashiCorp official repo)
# =============================================================================
info "Installing Terraform..."
if ! command -v terraform &>/dev/null; then
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update -qq
  sudo apt-get install -y terraform
fi
pass "Terraform: $(terraform version -json 2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin)["terraform_version"])' 2>/dev/null || terraform version | head -1)"

# =============================================================================
# 3. AWS CLI v2
# =============================================================================
info "Installing AWS CLI v2..."
if ! command -v aws &>/dev/null; then
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q /tmp/awscliv2.zip -d /tmp/
  sudo /tmp/aws/install
  rm -rf /tmp/awscliv2.zip /tmp/aws
fi
pass "AWS CLI: $(aws --version 2>/dev/null)"

# =============================================================================
# 4. GitHub CLI
# =============================================================================
info "Installing GitHub CLI..."
if ! command -v gh &>/dev/null; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update -qq && sudo apt-get install -y gh
fi
pass "GitHub CLI: $(gh --version | head -1)"

# =============================================================================
# 5. OPA (Open Policy Agent) — NIS2 compliance
# =============================================================================
info "Installing OPA..."
if ! command -v opa &>/dev/null; then
  OPA_VERSION="0.68.0"
  curl -fsSL "https://openpolicyagent.org/downloads/v${OPA_VERSION}/opa_linux_amd64_static" -o /tmp/opa
  chmod +x /tmp/opa
  sudo mv /tmp/opa /usr/local/bin/opa
fi
pass "OPA: $(opa version 2>/dev/null | head -1)"

# =============================================================================
# 6. tfsec (Terraform security scanner)
# =============================================================================
info "Installing tfsec..."
if ! command -v tfsec &>/dev/null; then
  TFSEC_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/tfsec/releases/latest | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])" 2>/dev/null || echo "v1.28.11")
  curl -fsSL "https://github.com/aquasecurity/tfsec/releases/download/${TFSEC_VERSION}/tfsec-linux-amd64" -o /tmp/tfsec
  chmod +x /tmp/tfsec
  sudo mv /tmp/tfsec /usr/local/bin/tfsec
fi
pass "tfsec: $(tfsec --version 2>/dev/null | head -1)"

# =============================================================================
# 7. Checkov (Bridgecrew compliance)
# =============================================================================
info "Installing checkov..."
if ! command -v checkov &>/dev/null; then
  pip3 install checkov --quiet --break-system-packages 2>/dev/null || pip3 install checkov --quiet
fi
pass "checkov: $(checkov --version 2>/dev/null)"

# =============================================================================
# 8. gitleaks (Secrets scanning — NIS2 Art.25)
# =============================================================================
info "Installing gitleaks..."
if ! command -v gitleaks &>/dev/null; then
  GL_VERSION=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])" 2>/dev/null || echo "v8.18.4")
  curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/${GL_VERSION}/gitleaks_${GL_VERSION#v}_linux_x64.tar.gz" -o /tmp/gitleaks.tar.gz
  tar -xzf /tmp/gitleaks.tar.gz -C /tmp/
  sudo mv /tmp/gitleaks /usr/local/bin/gitleaks
  rm /tmp/gitleaks.tar.gz
fi
pass "gitleaks: $(gitleaks version 2>/dev/null)"

# =============================================================================
# 9. pre-commit
# =============================================================================
info "Installing pre-commit..."
if ! command -v pre-commit &>/dev/null; then
  pip3 install pre-commit --quiet --break-system-packages 2>/dev/null || pip3 install pre-commit --quiet
fi
pass "pre-commit: $(pre-commit --version 2>/dev/null)"

# =============================================================================
# 10. kubectl
# =============================================================================
info "Installing kubectl..."
if ! command -v kubectl &>/dev/null; then
  curl -fsSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /tmp/kubectl
  chmod +x /tmp/kubectl
  sudo mv /tmp/kubectl /usr/local/bin/kubectl
fi
pass "kubectl: $(kubectl version --client --short 2>/dev/null | head -1)"

# =============================================================================
# 11. Setup repo
# =============================================================================
info "Setting up repository..."
if [ -f ".pre-commit-config.yaml" ]; then
  pre-commit install
  pass "pre-commit hooks installed"
fi
chmod +x scripts/*.sh 2>/dev/null || true

# =============================================================================
# 12. AWS check
# =============================================================================
if aws sts get-caller-identity &>/dev/null; then
  ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
  REGION=$(aws configure get region 2>/dev/null || echo "NOT SET")
  pass "AWS configured (Account: $ACCOUNT, Region: $REGION)"
  if [[ "$REGION" != eu-* ]]; then
    warn "Region '$REGION' is not EU — NIS2 requires eu-central-1"
    echo "  Fix: aws configure set region eu-central-1"
  fi
else
  warn "AWS not configured. Run: aws configure"
fi

echo ""
echo -e "${GREEN}✅ Linux setup complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. aws configure                  # AWS credentials"
echo "  2. make validate                  # Compliance check"
echo "  3. cd envs/dev && terraform init  # Init Terraform"
