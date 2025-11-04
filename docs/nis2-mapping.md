# NIS2 Directive Mapping

> **Security & Disclosure Notice**
> This repository is published for educational and professional portfolio purposes.
> All configurations, screenshots, and identifiers are anonymized and **do not represent any active AWS account or production environment**.
> Secrets, access keys, and real infrastructure data have been removed in accordance with responsible disclosure practices.

This document maps the AWS Secure Multi-Account Baseline (Terraform + OPA + AWS services) to the **NIS2 Directive** (Directive (EU) 2022/2555), focusing on **Article 21 (cybersecurity risk management)** and **Article 23 (incident reporting)**.

---

## Article 21 — Cybersecurity Risk Management

| NIS2 Requirement | Implementation Example |
|------------------|-------------------------|
| Art. 21(2)(a) — Governance & risk management policies | AWS Organizations SCPs (deny root, deny non-approved regions) + Terraform OPA enforcement |
| Art. 21(2)(b) — Access control & asset management | IAM permission boundaries, MFA enforcement, Entra ID Conditional Access + PIM |
| Art. 21(2)(c) — Risk assessment | AWS Config + Conformance Packs (detect drift, compliance gaps) |
| Art. 21(2)(d) — Event logging & monitoring | CloudTrail org trail, GuardDuty findings, Security Hub dashboards |
| Art. 21(2)(e) — Supply chain security | SBOM generation (Syft/Grype) + dependency scanning in CI/CD |
| Art. 21(2)(f) — Cryptography & encryption | S3 SSE-KMS, CloudTrail log file validation, KMS key rotation |
| Art. 21(2)(g) — Incident handling | GuardDuty integration with SIEM (Sentinel/Splunk) for detection + response |

---

## Article 23 — Incident Reporting

| NIS2 Requirement | Implementation Example |
|------------------|-------------------------|
| Initial notification within 24 hours | CloudTrail + GuardDuty alerts forwarded to Sentinel (incident ticket automation) |
| Intermediate update within 72 hours | AWS Security Hub findings centralized for ongoing reporting |
| Final report within 1 month | SIEM evidence exports (JSON/CSV) archived in S3 for audit-ready retention |

---

### Conclusion

The AWS secure multi-account baseline provides **preventive controls** (IAM, encryption, SCPs), **detective controls** (GuardDuty, CloudTrail), and **governance controls** (Terraform + OPA policy enforcement) that directly satisfy NIS2 requirements for essential and important entities.
