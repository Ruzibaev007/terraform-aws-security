# Installation Guide

> Setup guide for **macOS**, **Linux**, and **Windows** — all tools needed to work with `terraform-aws-security`.

## Quick Start

| OS | Command |
|---|---|
| **macOS** | `bash install/macos.sh` |
| **Linux** (Ubuntu/Debian/Mint) | `bash install/linux.sh` |
| **Windows** (PowerShell as Admin) | `.\install\windows.ps1` |

---

## What Gets Installed

| Tool | Purpose | Required |
|---|---|---|
| `terraform >= 1.5` | Infrastructure as Code | ✅ |
| `aws-cli >= 2.13` | AWS API access | ✅ |
| `opa >= 0.68` | NIS2/DORA policy validation | ✅ |
| `tfsec` | Terraform security scanner | ✅ |
| `checkov` | Compliance scanner | ✅ |
| `gitleaks` | Secrets scanning (NIS2 Art.25) | ✅ |
| `git` | Version control | ✅ |
| `gh` | GitHub CLI | ✅ |
| `jq` | JSON processing | ✅ |
| `pre-commit` | Git hooks | ✅ |
| `kubectl` | Kubernetes (k3s module) | Optional |
| `infracost` | Cost estimation | Optional |

---

## macOS Setup

```bash
# Clone repo
git clone https://github.com/Protector080322/terraform-aws-security
cd terraform-aws-security

# Install all tools
bash install/macos.sh

# Configure AWS (Frankfurt for NIS2/GDPR)
aws configure
# AWS Access Key ID: [your key]
# AWS Secret Access Key: [your secret]
# Default region name: eu-central-1
# Default output format: json

# Verify
make validate
```

**Requirements:** macOS 13+ (Ventura), Apple Silicon or Intel

---

## Linux Setup

```bash
# Clone repo
git clone https://github.com/Protector080322/terraform-aws-security
cd terraform-aws-security

# Install all tools (Ubuntu/Debian/Linux Mint)
bash install/linux.sh

# Configure AWS
aws configure
# Region: eu-central-1

# Verify
make validate
```

**Requirements:** Ubuntu 20.04+, Debian 11+, Linux Mint 21+

---

## Windows Setup

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Clone repo
git clone https://github.com/Protector080322/terraform-aws-security
cd terraform-aws-security

# Install all tools
.\install\windows.ps1

# Configure AWS
aws configure
# Region: eu-central-1
```

**Requirements:** Windows 10/11, PowerShell 5+

> **Tip:** Install [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) with Ubuntu for best compatibility with Linux-based tools and scripts.

---

## Server Setup (CI/CD, Cloud VMs)

For servers running CI/CD pipelines (GitHub Actions, GitLab CI, Jenkins):

```bash
# Ubuntu Server 22.04 LTS
curl -fsSL https://raw.githubusercontent.com/Protector080322/terraform-aws-security/main/install/linux.sh | bash

# After install, configure service account credentials
aws configure --profile cicd
export AWS_PROFILE=cicd
```

For **GitHub Actions** — no local setup needed. The pipeline (`.github/workflows/plan.yml`) installs all tools automatically.

---

## Verify Installation

After setup, run:

```bash
# Full compliance check
make validate

# Or manually:
terraform -v                           # >= 1.5.0
aws --version                          # >= 2.13.0
opa version                            # >= 0.68.0
tfsec --version
checkov --version
gitleaks version
```

---

## Troubleshooting

### "terraform: command not found"
```bash
# macOS
brew install terraform

# Linux
sudo apt-get install terraform

# Windows
choco install terraform
```

### "AWS credentials not configured"
```bash
aws configure
# Region MUST be eu-central-1 for NIS2/GDPR
```

### "OPA tests failing"
```bash
# Run tests with verbose output
opa test policies-as-code/opa/ -v

# Check specific rule
opa eval --data policies-as-code/opa/policies.rego \
  --input envs/dev/plan.json \
  "data.terraform.security.result"
```

### "pre-commit hooks failing"
```bash
# Update hooks
pre-commit autoupdate

# Run manually
pre-commit run --all-files
```

---

## Minimum Hardware Requirements

| Component | Minimum | Recommended |
|---|---|---|
| RAM | 4 GB | 8+ GB |
| CPU | 2 cores | 4+ cores |
| Disk | 10 GB | 20+ GB |
| Internet | Required | Required |
| OS | See above | Ubuntu 22.04 LTS |
