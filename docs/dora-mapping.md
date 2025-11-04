# DORA (Digital Operational Resilience Act) Mapping

> **Security & Disclosure Notice**
> This repository is published for educational and professional portfolio purposes.
> All configurations, screenshots, and identifiers are anonymized and **do not represent any active AWS account or production environment**.
> Secrets, access keys, and real infrastructure data have been removed in accordance with responsible disclosure practices.

This document maps the AWS Secure Multi-Account Baseline (Terraform + OPA + AWS services) to the **Digital Operational Resilience Act (DORA — Regulation (EU) 2022/2554)**.

---

## Article 8 — ICT Risk Management

| DORA Requirement | Implementation Example |
|------------------|-------------------------|
| ICT risk management framework | Terraform baseline for IAM, encryption, logging guardrails |
| Security controls for ICT assets | AWS IAM SCPs, permission boundaries, KMS encryption |
| Monitoring & detection | CloudTrail org trail, GuardDuty threat detection, Security Hub dashboards |
| Access management | MFA, IAM role federation, Entra ID PIM for JIT admin access |
| Data protection | S3 SSE-KMS, CloudTrail log file validation, encrypted Terraform state |

---

## Article 23 — ICT Incident Reporting

| DORA Requirement | Implementation Example |
|------------------|-------------------------|
| Incident detection | GuardDuty + Security Hub alerts |
| Incident classification | Terraform tagging + severity mapping in SIEM |
| Timely reporting | Sentinel/Splunk rules forwarding alerts within required SLAs |
| Retention & evidence | S3 logging buckets (immutable, versioned, encrypted) |

---

## Article 30 — ICT Third-Party Risk Management

| DORA Requirement | Implementation Example |
|------------------|-------------------------|
| Register of information (outsourced services) | Terraform outputs + SBOM artifacts stored in GitHub Actions pipeline |
| Third-party monitoring | Syft/Grype scans integrated in CI/CD for open-source dependencies |
| Vendor governance | AWS Organizations service control policies ensuring only approved regions/vendors |
| Audit readiness | CI/CD compliance reports exported as PDF for audit submission |

---

### Conclusion

The AWS secure multi-account baseline, automated with Terraform and Policy-as-Code, provides **operational resilience controls** that satisfy DORA Articles 8, 23, and 30 — enabling financial entities to meet EU regulatory deadlines with audit-ready evidence.
