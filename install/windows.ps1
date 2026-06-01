# =============================================================================
# install/windows.ps1 — Setup for Windows 10/11 (PowerShell 5+)
# terraform-aws-security by Protector080322
# Run as Administrator: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# =============================================================================

$ErrorActionPreference = "Stop"

function pass($msg) { Write-Host "✅ $msg" -ForegroundColor Green }
function info($msg) { Write-Host "ℹ️  $msg" -ForegroundColor Cyan }
function warn($msg) { Write-Host "⚠️  $msg" -ForegroundColor Yellow }

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  terraform-aws-security — Windows Setup"       -ForegroundColor Cyan
Write-Host "  github.com/Protector080322/terraform-aws-security" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# =============================================================================
# 1. Check & Install Chocolatey
# =============================================================================
info "Checking Chocolatey..."
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    info "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    refreshenv
}
pass "Chocolatey ready"

# =============================================================================
# 2. Core Tools via Chocolatey
# =============================================================================
info "Installing core tools..."

$CoreTools = @(
    "terraform",
    "awscli",
    "git",
    "jq",
    "gh",          # GitHub CLI
    "python3"
)

foreach ($tool in $CoreTools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        info "Installing $tool..."
        choco install $tool -y --no-progress
        refreshenv
    }
    pass "$tool installed"
}

# =============================================================================
# 3. Security Tools
# =============================================================================
info "Installing security tools..."

# OPA (Open Policy Agent)
if (-not (Get-Command opa -ErrorAction SilentlyContinue)) {
    info "Installing OPA..."
    $opaVersion = "0.68.0"
    $opaUrl = "https://openpolicyagent.org/downloads/v$opaVersion/opa_windows_amd64.exe"
    $opaPath = "$env:ProgramFiles\OPA\opa.exe"
    New-Item -ItemType Directory -Force -Path "$env:ProgramFiles\OPA" | Out-Null
    Invoke-WebRequest -Uri $opaUrl -OutFile $opaPath
    # Add to PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if ($currentPath -notlike "*OPA*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$env:ProgramFiles\OPA", "Machine")
    }
    refreshenv
}
pass "OPA installed"

# tfsec
if (-not (Get-Command tfsec -ErrorAction SilentlyContinue)) {
    info "Installing tfsec..."
    choco install tfsec -y --no-progress
    refreshenv
}
pass "tfsec installed"

# checkov via pip
if (-not (Get-Command checkov -ErrorAction SilentlyContinue)) {
    info "Installing checkov..."
    pip install checkov --quiet
}
pass "checkov installed"

# gitleaks
if (-not (Get-Command gitleaks -ErrorAction SilentlyContinue)) {
    info "Installing gitleaks..."
    choco install gitleaks -y --no-progress
    refreshenv
}
pass "gitleaks installed"

# pre-commit
if (-not (Get-Command pre-commit -ErrorAction SilentlyContinue)) {
    pip install pre-commit --quiet
}
pass "pre-commit installed"

# kubectl
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    choco install kubernetes-cli -y --no-progress
    refreshenv
}
pass "kubectl installed"

# =============================================================================
# 4. Windows Terminal (recommended)
# =============================================================================
info "Checking Windows Terminal..."
if (Get-Command wt -ErrorAction SilentlyContinue) {
    pass "Windows Terminal already installed"
} else {
    warn "Windows Terminal not found. Install from Microsoft Store for best experience."
}

# =============================================================================
# 5. WSL2 Check (recommended for Linux tools)
# =============================================================================
info "Checking WSL2..."
$wslStatus = wsl --status 2>&1
if ($LASTEXITCODE -eq 0) {
    pass "WSL2 is available"
    info "Tip: You can also use install/linux.sh inside WSL2 for full compatibility"
} else {
    warn "WSL2 not enabled. Enable with: wsl --install (requires restart)"
}

# =============================================================================
# 6. AWS Configuration
# =============================================================================
info "Checking AWS CLI..."
try {
    $identity = aws sts get-caller-identity 2>&1 | ConvertFrom-Json
    $account = $identity.Account
    $region = aws configure get region 2>&1
    pass "AWS configured (Account: $account, Region: $region)"
    if ($region -notmatch "^eu-") {
        warn "Region '$region' is not EU — NIS2 requires eu-central-1"
        Write-Host "  Fix: aws configure set region eu-central-1" -ForegroundColor Yellow
    }
} catch {
    warn "AWS not configured. Run: aws configure"
    Write-Host "  Required: Access Key ID, Secret Key, Region=eu-central-1" -ForegroundColor Yellow
}

# =============================================================================
# 7. Repository setup
# =============================================================================
info "Setting up repository..."
if (Test-Path ".pre-commit-config.yaml") {
    pre-commit install
    pass "pre-commit hooks installed"
}

# =============================================================================
# 8. Summary
# =============================================================================
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Verification Summary"                          -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$CheckTools = @("terraform", "aws", "git", "jq", "gh", "opa", "tfsec", "checkov", "gitleaks", "kubectl", "pre-commit")
foreach ($tool in $CheckTools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        pass "$tool"
    } else {
        warn "$tool — NOT found"
    }
}

Write-Host ""
Write-Host "✅ Windows setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. aws configure                               # AWS credentials"
Write-Host "  2. cd envs\dev && terraform init              # Init Terraform"
Write-Host "  3. terraform plan                             # Preview changes"
Write-Host "  4. .\scripts\validate-compliance.sh (WSL2)   # Compliance check"
Write-Host ""
Write-Host "Tip: Use WSL2 with Ubuntu for best Linux tool compatibility" -ForegroundColor Yellow
