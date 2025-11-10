[![terraform-security-checks](https://github.com/amina0806/terraform-aws-security-multi-account/actions/workflows/plan.yml/badge.svg)](https://github.com/amina0806/terraform-aws-security-multi-account/actions/workflows/plan.yml)

# AWS Multi-Framework Compliance-as-Code Baseline

> This open-core baseline demonstrates how to automate **identity, access, and compliance governance** across multi-account AWS environments using **Infrastructure-as-Code** and **Policy-as-Code**.

---

##  Key Capabilities

- **IAM Governance-as-Code** — Permission boundaries, MFA enforcement, and least-privilege policies.
- **Compliance-as-Code** — Controls mapped to ISO 27001, NIS2, and DORA requirements.
- **Continuous Validation** — Automated policy testing using OPA/Rego, tfsec, and Checkov.
- **Evidence Automation** — Generate version-controlled audit artifacts.
- **Multi-Cloud Extensibility** — Designed for AWS, extendable to Azure and GCP.

---

##  Sample Compliance Mapping

| Control ID | Description | Framework Reference | Terraform Implementation | Evidence Artifact |
|-------------|-------------|--------------------|--------------------------|-------------------|
| GCC-LOG-001 | Centralized Logging & Encryption | ISO 27001 A.12.4.1, DORA 9(2)(f) | aws_cloudtrail, aws_kms_key | OPA: cloudtrail_encryption_enabled |
| GCC-IAM-002 | IAM Governance | NIS2 Art.21(2)(b) | aws_iam_policy, permission_boundary.tf | OPA: iam_boundary_pass.rego |

> *This table is a limited preview.
> The full mapping library (100+ controls, 10+ frameworks) is proprietary and available under license.*

---

## Architecture Diagram
![Architecture Diagram](docs/architecture-diagram.png)

---

## CI/CD Security Gates

- Terraform validate → tfsec → Checkov → OPA test
- Fail-fast CI pipeline (GitHub Actions)
- Demonstrates automated control validation

---

## Intellectual Property Notice

This repository contains the **public open-core baseline** of the Global Compliance Code™ Framework.
The complete multi-framework mappings, control ontology, and evidence logic are proprietary to **Global Compliance Code OÜ**.
Commercial licensing or partnership inquiries: contact@globalcompliancecode.com

---

### AWS Multi-Framework Compliance Baseline

by **GlobalComplianceCode**
Maintained by [Amina Jiyu An](https://www.linkedin.com/in/amina0806)
GitHub: [github.com/amina0806](https://github.com/amina0806)
