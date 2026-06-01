# Changelog

All notable changes to this project are documented here.

## [v2.0.0] — 2026-06-01 (Protector080322 Release)

### 🚀 Major Upgrade

**NIS2/DORA compliance overhaul** — from basic AWS baseline to production-ready compliance framework.

### 🔴 Critical Fixes

- **FIXED:** `enable_cloudtrail = false` → `true` (CloudTrail was disabled!)
- **FIXED:** `allowed_regions = ["us-east-1"]` → EU regions (GDPR/NIS2 data residency)
- **FIXED:** `enable_deny_root_user = false` → `true` (root account unprotected)
- **FIXED:** `enable_require_mfa_iam = false` → `true` (MFA not enforced)
- **FIXED:** `gd_enable_eks_audit_logs = false` → `true` (EKS threats undetected)

### ✨ New Features

**Documentation:**
- `README.md` — Professional 5-minute quick start
- `GETTING_STARTED.md` — Step-by-step deployment guide
- `ARCHITECTURE.md` — 7 Mermaid diagrams (NIS2/DORA architecture)
- `docs/compliance-mapping.md` — 35+ controls mapped to NIS2/DORA/ISO 27001

**NIS2 Compliance:**
- `compliance/nis2/article-21-access-control.tf` — MFA, RBAC, PAM, sessions
- `compliance/nis2/article-23-incident-response.tf` — Lambda playbook, BSI 72h reporting
- `compliance/nis2/article-25-audit-logging.tf` — S3 Object Lock, KMS, 7-year retention

**DORA Compliance:**
- `compliance/dora/article-16-incident-reporting.tf` — Step Functions: 4h/72h/1-month BaFin

**Industry Examples:**
- `examples/mittelstand-sme/` — German manufacturing company (500 employees)
- `examples/healthcare/` — GDPR Art.9 + NIS2 essential operator
- `examples/automotive/` — TISAX + ISO-SAE-21434 + NIS2

**Kubernetes:**
- `kubernetes/k3s-hardened/main.tf` — NIS2 Art.21/32 hardened cluster
- `kubernetes/k3s-hardened/bootstrap-k3s.sh` — SSH hardening, UFW, auditd

**Automation:**
- `scripts/validate-compliance.sh` — Pre-deploy NIS2/DORA validation
- `scripts/generate-report.sh` — Automated compliance report generator

**CI/CD:**
- `.github/workflows/plan.yml` — 6-job pipeline: fmt → tfsec → OPA → plan → report → deploy
- OPA policy validation integrated into every PR

### 📊 Security Controls Added

- 4 new Organization SCPs (CloudTrail, GuardDuty, SecurityHub, S3 public access)
- 20+ OPA/Rego compliance rules (NIS2/DORA/ISO 27001)
- CloudWatch alarms for root login, MFA disable, GuardDuty disable
- Automated incident response Lambda (GuardDuty → classify → notify → report)
- DORA Step Functions workflow (4h → 72h → 1-month reporting)
- AWS Backup with cross-region DR (NIS2 Art.17)

---

## [v0.1.0] — 2025-11-10 (Original GlobalComplianceCode Baseline)

Initial public release of AWS multi-account security baseline.

- Multi-account structure (dev/prod environments)
- Basic IAM permission boundaries
- CloudTrail + KMS logging module
- OPA/Rego policy basics (GuardDuty, SecurityHub)
- GitHub Actions CI/CD pipeline
