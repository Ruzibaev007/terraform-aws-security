# Compliance Control Mapping

> Full mapping of infrastructure controls to **NIS2, DORA, ISO 27001, and BSI IT-Grundschutz**.

## NIS2 Article Mapping

| Control ID | NIS2 Article | Description | Implementation | File |
|---|---|---|---|---|
| NIS2-21-01 | Art. 21(1) | MFA enforcement | `aws_iam_policy.nis2_enforce_mfa` | `compliance/nis2/article-21-access-control.tf` |
| NIS2-21-02 | Art. 21(2) | RBAC — auditor role | `aws_iam_role.nis2_auditor` | `compliance/nis2/article-21-access-control.tf` |
| NIS2-21-03 | Art. 21(3) | Break-glass PAM role | `aws_iam_role.nis2_break_glass` | `compliance/nis2/article-21-access-control.tf` |
| NIS2-21-04 | Art. 21(4) | Session timeout 8h | `aws_iam_policy.nis2_session_policy` | `compliance/nis2/article-21-access-control.tf` |
| NIS2-21-05 | Art. 21(5) | Access key rotation 90d | `aws_config_config_rule.nis2_access_key_rotation` | `compliance/nis2/article-21-access-control.tf` |
| NIS2-21-06 | Art. 21(1) | MFA Config rule | `aws_config_config_rule.nis2_mfa_enabled` | `compliance/nis2/article-21-access-control.tf` |
| NIS2-21-07 | Art. 21(3) | No root access key | `aws_config_config_rule.nis2_no_root_access_key` | `compliance/nis2/article-21-access-control.tf` |
| NIS2-23-01 | Art. 23(1) | GuardDuty enabled | `aws_config_config_rule.nis2_guardduty_enabled` | `compliance/nis2/article-23-incident-response.tf` |
| NIS2-23-02 | Art. 23(1) | Security Hub enabled | `aws_config_config_rule.nis2_securityhub_enabled` | `compliance/nis2/article-23-incident-response.tf` |
| NIS2-23-03 | Art. 23(2) | Incident classification | `aws_sns_topic.nis2_critical_incidents` | `compliance/nis2/article-23-incident-response.tf` |
| NIS2-23-04 | Art. 23(3) | 72h BSI reporting | `aws_lambda_function.nis2_playbook` | `compliance/nis2/article-23-incident-response.tf` |
| NIS2-23-05 | Art. 23(3) | Auto incident response | `aws_sfn_state_machine` | `envs/dev/step4-security.tf` |
| NIS2-25-01 | Art. 25(1) | KMS encryption at rest | `aws_kms_key.audit_logs` | `compliance/nis2/article-25-audit-logging.tf` |
| NIS2-25-02 | Art. 25(1) | KMS key rotation | `enable_key_rotation = true` | `compliance/nis2/article-25-audit-logging.tf` |
| NIS2-25-03 | Art. 25(2) | S3 Object Lock (tamper-proof) | `aws_s3_bucket_object_lock_configuration` | `compliance/nis2/article-25-audit-logging.tf` |
| NIS2-25-04 | Art. 25(3) | CloudTrail log validation | `enable_log_file_validation = true` | `compliance/nis2/article-25-audit-logging.tf` |
| NIS2-25-05 | Art. 25(3) | Multi-region CloudTrail | `is_multi_region_trail = true` | `compliance/nis2/article-25-audit-logging.tf` |
| NIS2-25-06 | Art. 25(4) | 365-day log retention | `aws_s3_bucket_lifecycle_configuration` | `compliance/nis2/article-25-audit-logging.tf` |
| NIS2-25-07 | Art. 25(1) | S3 encryption Config rule | `aws_config_config_rule.s3_encryption` | `compliance/nis2/article-25-audit-logging.tf` |
| NIS2-25-08 | Art. 25(1) | RDS encryption Config rule | `aws_config_config_rule.rds_encryption` | `compliance/nis2/article-25-audit-logging.tf` |
| NIS2-28-01 | Art. 28 | EU region restriction SCP | `aws_organizations_policy` | `envs/dev/step6-org-scps.tf` |
| NIS2-32-01 | Art. 32 | Deny S3 public access SCP | `aws_organizations_policy.deny_s3_public_access` | `envs/dev/step6-org-scps.tf` |
| NIS2-32-02 | Art. 32 | Deny disable GuardDuty SCP | `aws_organizations_policy.deny_disable_guardduty` | `envs/dev/step6-org-scps.tf` |
| NIS2-32-03 | Art. 32 | Deny disable CloudTrail SCP | `aws_organizations_policy.deny_disable_cloudtrail` | `envs/dev/step6-org-scps.tf` |

---

## DORA Article Mapping

| Control ID | DORA Article | Description | Implementation | File |
|---|---|---|---|---|
| DORA-16-01 | Art. 16(1) | Incident classification | `aws_lambda_function.dora_classifier` | `compliance/dora/article-16-incident-reporting.tf` |
| DORA-16-02 | Art. 16(2) | 4h initial notification | `aws_sfn_state_machine.dora_incident_workflow` | `compliance/dora/article-16-incident-reporting.tf` |
| DORA-16-03 | Art. 16(3) | 72h intermediate report | Step Functions Wait state | `compliance/dora/article-16-incident-reporting.tf` |
| DORA-16-04 | Art. 16(4) | 1-month final report | Step Functions workflow | `compliance/dora/article-16-incident-reporting.tf` |
| DORA-16-05 | Art. 16 | BaFin notification | `aws_sns_topic.dora_supervisor` | `compliance/dora/article-16-incident-reporting.tf` |

---

## ISO 27001:2022 Mapping

| Control ID | ISO 27001 Control | Description | Implementation |
|---|---|---|---|
| ISO-A5-01 | A.5.1 | Information security policies | `README.md`, `docs/` |
| ISO-A5-15 | A.5.15 | Access control | `modules/iam/permission-boundary/` |
| ISO-A5-16 | A.5.16 | Identity management | `envs/dev/step7-iam-governance.tf` |
| ISO-A5-17 | A.5.17 | Authentication information | `compliance/nis2/article-21-access-control.tf` |
| ISO-A8-05 | A.8.5 | Secure authentication | MFA policy `NIS2-Article21-EnforceMFA` |
| ISO-A8-15 | A.8.15 | Logging | `modules/logging/main.tf` |
| ISO-A8-16 | A.8.16 | Monitoring activities | CloudWatch alarms |
| ISO-A8-20 | A.8.20 | Networks security | `kubernetes/k3s-hardened/main.tf` |
| ISO-A8-24 | A.8.24 | Use of cryptography | `aws_kms_key` resources |
| ISO-A8-34 | A.8.34 | Protection of information systems during audit testing | OPA policies, tfsec, checkov |

---

## BSI IT-Grundschutz Mapping

| BSI Control | Description | NIS2 Equivalent | Implementation |
|---|---|---|---|
| ORP.4 | Identity & Access Management | Art. 21 | `modules/iam/` |
| CON.1 | Cryptography Concept | Art. 25 | `modules/logging/main.tf` |
| OPS.1.1.5 | Data Backup | Art. 17 | `examples/*/terraform.tfvars` |
| DER.2.1 | Incident Management | Art. 23 | `compliance/nis2/article-23-incident-response.tf` |
| INF.14 | Automation Networks | Art. 32 | `kubernetes/k3s-hardened/` |
| NET.1.1 | Network Architecture | Art. 32 | `envs/dev/step6-org-scps.tf` |

---

## CI/CD Security Gates

Every pull request triggers:

```
terraform fmt -check          → Code quality
    ↓
tfsec (HIGH+ severity)        → Security scan
    ↓
checkov                       → Compliance scan
    ↓
OPA opa test                  → Policy unit tests
    ↓
terraform plan + OPA eval     → Plan compliance check
    ↓
terraform apply               → Deploy (main branch only)
```

**Pipeline file:** `.github/workflows/plan.yml`

---

## Quick Reference: Who Needs What

| Company Type | Required Frameworks | Key Controls |
|---|---|---|
| German Mittelstand (manufacturing) | NIS2 + ISO 27001 | Art. 21, 23, 25 |
| Bank / Insurance | DORA + NIS2 + ISO 27001 | All + DORA Art. 16 |
| Healthcare | NIS2 + GDPR + ISO 27001 | Art. 21, 25 + GDPR Art.9 |
| Automotive / Tier-1 supplier | TISAX + NIS2 + ISO-SAE-21434 | Art. 21, 28, 32 |
| Cloud / SaaS provider | NIS2 + ISO 27001 | Art. 21, 23, 32 |
