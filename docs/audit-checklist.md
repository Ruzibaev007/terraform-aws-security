
# Audit Checklist — AWS Secure Baseline (Terraform + PaC)

> **Security & Disclosure Notice**
> This repository is published for educational and professional portfolio purposes.
> All configurations, screenshots, and identifiers are anonymized and **do not represent any active AWS account or production environment**.
> Secrets, access keys, and real infrastructure data have been removed in accordance with responsible disclosure practices.


Evidence links point to screenshots and mappings in the repo.

---

## Step 1 — Remote State (S3 + DynamoDB)
- [ ] S3 backend bucket created with **SSE-KMS** ([screenshot](screenshots/step1/state-s3-backend.png))
- [ ] Bucket versioning enabled
- [ ] DynamoDB table for state locking ([screenshot](screenshots/step1/state-dynamodb.png))
- [ ] IAM scoped to pipeline role
- [ ] ISO 27001 mapping: A.8.20 / 8.24, A.5.23 / 5.23

---

## Step 2 — Centralized Logging
- [ ] Organization-wide CloudTrail enabled ([screenshot](screenshots/step2/cloudtrail-settings.png))
- [ ] Log bucket with **BPA ON + SSE-KMS** ([screenshot](screenshots/step2/s3-encryption.png))
- [ ] Log file validation enabled
- [ ] CloudWatch Logs encrypted + retention configured
- [ ] ISO 27001 mapping: A.12.4 / 8.15, A.8.24 / 8.12

---

## Step 3 — AWS Config & Conformance Packs
- [ ] Config recorder enabled ([screenshot](screenshots/step3/config_settings.png))
- [ ] Delivery channel created ([screenshot](screenshots/step3/cli_delivery_channels.png))
- [ ] Conformance Pack deployed ([screenshot](screenshots/step3/conformance_pack.png))
- [ ] Evidence bucket receiving artifacts
- [ ] ISO 27001 mapping: A.12.1 / 5.14, A.18.2.3 / 5.35

---

## Step 4 — Security Hub & GuardDuty
- [ ] Security Hub account enabled ([screenshot](screenshots/step4/security-hub-summary.png))
- [ ] CIS + AFSBP standards subscribed
- [ ] GuardDuty detector active with S3 + Malware Protection ([screenshot](screenshots/step4/guardduty-settings.png))
- [ ] Findings aggregated at Org admin
- [ ] ISO 27001 mapping: A.12.6 / 8.8, A.16.1 / 5.25

---

## Step 5 — Policy-as-Code (OPA/Rego, tfsec, Checkov)
- [ ] `terraform plan` produces `plan.json`
- [ ] `tfsec` and `Checkov` pass locally/CI
- [ ] `opa eval` denies missing Security Hub/GuardDuty ([screenshot](screenshots/step5/opa_eval_fail_missing_guardduty.png))
- [ ] `opa test` passes all unit tests ([screenshot](screenshots/step5/opa_test_pass.png))
- [ ] GitHub Actions badge green ([screenshot](screenshots/step5/ci-badge-step5.png))
- [ ] ISO 27001 mapping: A.12.1.2 / 5.14, A.18.2.3 / 5.35

---

## Step 6 — AWS Organizations & SCPs
- [ ] Org enabled with **All Features** ([screenshot](screenshots/step6/org-settings-all-features.png))
- [ ] OUs created (security, workloads, sandbox, infra) ([screenshot](screenshots/step6/org-ous-list.png))
- [ ] SCPs attached to Root or OUs ([screenshot](screenshots/step6/org-root-attached-scps.png))
- [ ] Restrict Regions SCP in place ([screenshot](screenshots/step6/scp-restrict-regions-json.png))
- [ ] Protect Security Services SCP in place ([screenshot](screenshots/step6/scp-protectsecurityservices-json.png))
- [ ] (Optional) Require MFA / Deny Root toggles applied
- [ ] ISO 27001 mapping: A.5.1.1 / 5.1, A.9.1.2 / 5.12

---

## Step 7 — IAM Governance (Permissions Boundary + MFA Conditional Policy)
- [ ] Terraform plan & apply completed successfully ([screenshot](screenshots/step7/tf-plan.png))
- [ ] IAM Policies created: **org-permissions-boundary** & **mfa-conditional-policy** ([screenshot](screenshots/step7/iam-policies-list.png))
- [ ] Boundary Policy JSON reviewed — Deny privilege escalation + enforce S3 SSE-KMS ([screenshot](screenshots/step7/permissions-boundary-json.png))
- [ ] IAM user `dev-user` attached to both governance policies ([screenshot](screenshots/step7/dev-user-policies.png))
- [ ] Terraform outputs show both policy ARNs ([screenshot](screenshots/step7/tf-outputs.png))
- [ ] ISO 27001 mapping: A.5.18 / A.8.23
- [ ] NIS2 mapping: Article 21 §2 (b) — Access control & identity management
- [ ] DORA mapping: Article 8 / 11 — ICT risk management & identity governance

---

## Summary
Deployment proves:
- **Preventive controls** — SCPs, Permissions Boundaries, and MFA Conditional Policies block misconfigurations and privilege escalation before they occur.
- **Detective controls** — AWS Config, Security Hub, and GuardDuty continuously monitor for deviations.
- **Governance integration** — IAM Governance layer ensures identity enforcement through Terraform-defined guardrails aligned with least-privilege and MFA assurance.
- **Strong evidence** — Terraform code, state outputs, and screenshots demonstrate end-to-end security automation and compliance validation.
- **Compliance mappings** — ISO 27001 (A.5.18, A.8.23), NIS2 (Art. 21 §2 b), DORA (Art. 8 / 11), NIST CSF, PCI DSS, and CIS AWS Foundations Benchmarks.
