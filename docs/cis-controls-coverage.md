# CIS AWS Foundations Controls Coverage

> **Security & Disclosure Notice**
> This repository is published for educational and professional portfolio purposes.
> All configurations, screenshots, and identifiers are anonymized and **do not represent any active AWS account or production environment**.
> Secrets, access keys, and real infrastructure data have been removed in accordance with responsible disclosure practices.


This document shows how the Secure AWS Baseline project enforces CIS AWS Foundations Benchmark controls.

---

## Covered Controls by Step

### Step 1 — State Backend
- **CIS 2.1.1**: Ensure S3 bucket used for CloudTrail logs is not publicly accessible → S3 backend with Block Public Access.
- **CIS 2.2**: Ensure CloudTrail logs are encrypted → SSE-KMS for state bucket.

### Step 2 — Centralized Logging
- **CIS 2.1**: Ensure CloudTrail is enabled in all regions → centralized CloudTrail logging.
- **CIS 2.2**: Ensure CloudTrail log file validation is enabled → enabled on S3 bucket.
- **CIS 2.3**: Ensure CloudTrail logs are encrypted with KMS CMKs.

### Step 3 — Config & Conformance
- **CIS 2.5**: Ensure AWS Config is enabled in all regions.
- **CIS 2.6**: Ensure AWS Config records all resources.
- **CIS 2.7**: Ensure compliance packs enforce governance.

### Step 4 — Security Hub, GuardDuty
- **CIS 3.1**: Ensure GuardDuty is enabled.
- **CIS 3.2**: Ensure Security Hub is enabled and standards are subscribed.
- **CIS 4.x**: Continuous monitoring of IAM and networking.

### Step 5 — OPA / Policy-as-Code
- **CIS 1.1**: Enforce MFA, IAM best practices.
- **CIS 2.x**: Prevent misconfigured logging by automated policy checks.
- **CIS 3.x**: GuardDuty and Security Hub enforced at plan stage.

### Step 6 — Organizations & SCPs
- **CIS 1.1, 1.5**: Enforce IAM security (MFA toggle, permission boundaries).
- **CIS 1.6**: Ensure root account is not used (DenyRoot SCP).
- **CIS 2.1**: CloudTrail cannot be disabled (ProtectSecurityServices SCP).
- **CIS 1.3**: Restrict non-approved regions.
