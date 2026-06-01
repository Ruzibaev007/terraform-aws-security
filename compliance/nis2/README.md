# NIS2 Compliance Implementation

> Terraform examples for **NIS2 Directive (EU) 2022/2555** — EU Cybersecurity Directive for essential and important operators.

## Articles Covered

| Article | Topic | File | Status |
|---------|-------|------|--------|
| **Art. 21** | Access Control & MFA | `article-21-access-control.tf` | ✅ |
| **Art. 23** | Incident Detection & Response | `article-23-incident-response.tf` | ✅ |
| **Art. 25** | Audit Logging & Encryption | `article-25-audit-logging.tf` | ✅ |
| **Art. 28** | Supply Chain Security | `article-28-supply-chain.tf` | 🚧 |
| **Art. 32** | Network Segmentation | `article-32-network-security.tf` | 🚧 |

## Quick Start

```bash
# Deploy Article 21 (Access Control)
cd compliance/nis2
terraform init
terraform apply -target=aws_iam_policy.nis2_enforce_mfa

# Run compliance check
../../scripts/validate-compliance.sh
```

## Who Needs This?

- **Essential operators**: energy, transport, banking, health, water, digital infrastructure
- **Important operators**: postal, waste, chemicals, food, manufacturing, digital providers

Germany's BSI enforces NIS2 — non-compliance: fines up to **€10 million** or 2% of global revenue.

## Reporting Obligations

| Incident Type | Deadline | Authority |
|---------------|----------|-----------|
| CRITICAL breach | **72 hours** | BSI (Bundesamt für Sicherheit in der Informationstechnik) |
| Major incident | **1 month** | BSI (full report) |
| BSI contact | | https://www.bsi.bund.de/meldung |
