# ISO/IEC 27001 Annex A — Control Mapping (2013 → 2022)

> **Security & Disclosure Notice**
> This repository is published for educational and professional portfolio purposes.
> All configurations, screenshots, and identifiers are anonymized and **do not represent any active AWS account or production environment**.
> Secrets, access keys, and real infrastructure data have been removed in accordance with responsible disclosure practices.


This document shows how the 2013 Annex A controls map into the 2022 revision across all steps of the Secure AWS Baseline project. It demonstrates awareness of both versions — useful since many organizations are still transitioning.

---

## Step 1 — State Backend (S3 + DynamoDB)

| Implementation Example | 2013 Control (old numbering) | 2022 Control (new numbering) |
|-------------------------|------------------------------|------------------------------|
| S3 backend with SSE-KMS | A.8.20 Use of cryptography | 8.24 Use of cryptography |
| Remote state segregation (multi-account, Org) | A.8.23 Information security in cloud services | 5.23 Information security for use of cloud services |
| DynamoDB state locking (Terraform state protection) | A.8.16 Access control | 5.15 Access control |

---

## Step 2 — Centralized Logging

| Implementation Example | 2013 Control | 2022 Control |
|-------------------------|--------------|--------------|
| CloudTrail & CloudWatch logging | A.12.4 Logging and monitoring | 8.15 Logging |
| CMK for encryption (KMS) | A.8.20 Use of cryptography | 8.24 Use of cryptography |
| Block Public Access, TLS-only | A.8.24 Data leakage prevention | 8.12 Data leakage prevention |
| Log file validation, versioned bucket | A.8.16 Monitoring activities | 8.16 Monitoring activities |

---

## Step 3 — AWS Config & Conformance Packs

| Implementation Example | 2013 Control | 2022 Control |
|-------------------------|--------------|--------------|
| AWS Config rules baseline | A.12.1 Security requirements of IS | 5.14 Information security requirements for information systems |
| Conformance pack compliance checks | A.18.2.2 Compliance with security policies & standards | 5.36 Compliance with policies, rules and standards for information security |
| Continuous compliance evaluation | A.12.7 Information systems audit considerations | 5.35 Independent review of information security |
| Resource compliance monitoring | A.8.16 Monitoring activities | 8.16 Monitoring activities |

---

## Step 4 — Security Hub, GuardDuty & Policy-as-Code

| Implementation Example | 2013 Control | 2022 Control |
|-------------------------|--------------|--------------|
| Security Hub findings aggregation | A.12.4 Logging & monitoring | 8.15 Logging |
| GuardDuty threat detection | A.12.6 Technical vulnerability management | 8.8 Management of technical vulnerabilities |
| Incident dashboard & response | A.16.1 Information security incident management | 5.25 Response to information security incidents |
| GuardDuty anomalous network alerts | A.13.1 Network security management | 8.20 Network security |
| Policy-as-Code enforcement in CI/CD | A.14.2 Security in development and support processes | 8.28 Secure coding |
| Security Hub standards (shared responsibility) | A.15.1 Information security in supplier relationships | 5.22 Information security in supplier relationships |

---

## Step 5 — OPA Policy-as-Code (Terraform Plan Evaluation)

| Implementation Example | 2013 Control | 2022 Control |
|-------------------------|--------------|--------------|
| GuardDuty enforcement via OPA (deny if missing) | A.12.6 Technical vulnerability management | 8.8 Management of technical vulnerabilities |
| Security Hub enforcement via OPA (deny if missing) | A.12.4 Logging & monitoring | 8.15 Logging |
| CIS/AFSBP standards subscription required | A.18.2.2 Compliance with security policies & standards | 5.36 Compliance with policies, rules and standards for information security |
| IAM principals must have permission boundaries | A.9.2.3 Management of privileged access rights | 5.18 Privileged access rights |
| S3 encryption required (SSE-KMS) | A.8.20 Use of cryptography | 8.24 Use of cryptography |
| Policy-as-Code unit tests (opa test) validate rules | A.12.1.2 Change management | 5.14 Information security requirements for information systems |
| GitHub Actions runs opa test in CI (portfolio mode) | A.18.2.3 Technical compliance review | 5.35 Independent review of information security |

---

## Step 6 — AWS Organizations & SCPs (Preventive Guardrails)

| Implementation Example | 2013 Control (old numbering) | 2022 Control (new numbering) |
|-------------------------|------------------------------|------------------------------|
| Deny leaving the organization (DenyLeaveOrg SCP) | A.6.1.1 Information security roles & responsibilities | 5.2 Information security roles and responsibilities |
| Protect Security Services (deny disabling CloudTrail, Config, GuardDuty, Security Hub) | A.12.4 Logging & monitoring | 8.15 Logging |
| Restrict use of non-approved AWS regions | A.9.1.2 Access to networks and network services | 5.12 Classification and handling of information |
| Require MFA for IAM write actions (toggle) | A.9.2.3 Management of privileged access rights | 5.18 Privileged access rights |
| Deny all for root account (toggle, break-glass only) | A.9.2.1 User registration and de-registration | 5.17 Identity management |
| Organization-wide governance with SCPs | A.5.1.1 Policies for information security | 5.1 Policies for information security |
| Terraform-managed multi-account OUs and policies | A.12.1.2 Change management | 5.14 Information security requirements for information systems |
