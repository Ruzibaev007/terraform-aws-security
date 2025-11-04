# PCI DSS Compliance Mapping

> **Security & Disclosure Notice**
> This repository is published for educational and professional portfolio purposes.
> All configurations, screenshots, and identifiers are anonymized and **do not represent any active AWS account or production environment**.
> Secrets, access keys, and real infrastructure data have been removed in accordance with responsible disclosure practices.


This document maps the AWS secure multi-account baseline to key **PCI DSS v4.0** requirements.

| Step | Implementation Example | PCI DSS Requirement |
|------|-------------------------|----------------------|
| 1 — State Backend | S3 backend SSE-KMS, DynamoDB lock | Req. 3.5 (Encryption of cardholder data at rest) |
| 2 — Centralized Logging | CloudTrail with KMS encryption, CloudWatch monitoring | Req. 10 (Logging and monitoring) |
| 3 — Config & Conformance | Config rules, Conformance packs | Req. 11.5 (File integrity & configuration monitoring) |
| 4 — Security Hub & GuardDuty | Threat detection and dashboards | Req. 12.10 (Incident response plan) |
| 5 — OPA Policy-as-Code | CI/CD enforcement of encryption/IAM | Req. 6.3 (Secure development practices) |
| 6 — Organizations & SCPs | SCPs restricting regions and services | Req. 7.2 (Restrict access to cardholder data) |

---
