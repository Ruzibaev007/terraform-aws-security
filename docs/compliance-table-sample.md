# 🌍 Compliance Mapping (Sample Extract)

> **Security & Disclosure Notice**
> This repository is published for educational and professional portfolio purposes.
> All configurations, screenshots, and identifiers are anonymized and **do not represent any active AWS account or production environment**.

---

## Framework Coverage (Demonstration Scope)

This baseline demonstrates alignment with key international and European cybersecurity frameworks:
- ISO/IEC 27001 (Annex A 2022)
- NIST Cybersecurity Framework (CSF)
- EU NIS2 Directive
- EU Digital Operational Resilience Act (DORA)
- PCI DSS (v4.0)

---

## One-Glance Compliance Mapping (Sample Extract)

| Step | Implementation Example | ISO/IEC 27001 | EU NIS2 | EU DORA |
|------|-------------------------|---------------|----------|----------|
| 2 — Centralized Logging | CloudTrail, CloudWatch, KMS | A.12.4 (Event logging) | Art. 21(2)(d) — Event monitoring | Art. 23 — Incident detection & reporting |
| 5 — OPA Policy-as-Code | Terraform plan evaluation | A.9.2.3 (Access control) | Art. 21(2)(a) — Governance & policies | Art. 8 — ICT controls automation |
| 6 — Organizational Guardrails | SCPs, Region Restriction | A.5.1.1 (Policies for information security) | Art. 21(2)(b) — Access control | Art. 30 — Third-party/vendor risk |

> *This sample demonstrates the structure of the Global Compliance Code™ multi-framework alignment model.
> The full library (100+ controls, 10+ frameworks, and detailed evidence mappings) is proprietary and available under commercial license.*

---

### Legend
- **NIS2**: Art. 21 = Cybersecurity risk management | Art. 23 = Incident detection & reporting
- **DORA**: Art. 8 = ICT risk management & controls | Art. 23 = ICT incident reporting | Art. 30 = Vendor oversight

---

### Conclusion
This sample shows how **Terraform-based cloud guardrails** can directly map to regulatory obligations under ISO 27001, NIS2, and DORA — forming the foundation for automated compliance assurance.
