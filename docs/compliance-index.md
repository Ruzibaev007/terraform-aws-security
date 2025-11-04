# Compliance Mapping Index

> **Security & Disclosure Notice**
> This repository is published for educational and professional portfolio purposes.
> All configurations, screenshots, and identifiers are anonymized and **do not represent any active AWS account or production environment**.
> Secrets, access keys, and real infrastructure data have been removed in accordance with responsible disclosure practices.


This repository demonstrates how a secure AWS multi-account baseline (built with Terraform, OPA, and AWS native services) aligns with international and European security frameworks.
This index links to detailed mapping documents and provides a one-glance summary table.

---

## Framework Coverage

- [ISO/IEC 27001 Annex A Mapping (2013 → 2022)](iso27001-mapping.md)
  Global best practice standard for Information Security Management Systems (ISMS). Includes dual mapping to both the 2013 and 2022 Annex A control sets.

- [NIST Cybersecurity Framework (CSF) Mapping](nist-csf-mapping.md)
  Mapping to the NIST Cybersecurity Framework (Identify, Protect, Detect, Respond, Recover).

- [PCI DSS Mapping](pci-dss-mapping.md)
  Coverage for payment card industry requirements, focused on encryption, access control, and monitoring.

- [EU — NIS2 Directive Mapping](nis2-mapping.md)
  Maps project steps to NIS2 cybersecurity requirements, especially Article 21 (cybersecurity risk management) and Article 23 (incident reporting).

- [EU — DORA (Digital Operational Resilience Act) Mapping](dora-mapping.md)
  Shows how the baseline supports compliance with DORA’s requirements for ICT risk management, incident handling, and third-party/vendor oversight.

- [CIS AWS Foundations Controls Coverage](cis-aws-foundations.md)
  Baseline AWS security controls based on the Center for Internet Security (CIS) AWS Foundations Benchmark.

---

## One-Glance Compliance Mapping (Summary)

This summary shows how the secure AWS multi-account baseline (Terraform + Policy-as-Code) aligns with **international standards** and **EU regulations**.

| Step | Implementation Example | ISO/IEC 27001 | NIST CSF | PCI DSS | EU NIS2 | EU DORA |
|------|-------------------------|---------------|----------|---------|---------|---------|
| 1 — State Backend | S3 backend SSE-KMS, DynamoDB lock | A.8.20 → 8.24 (crypto), A.8.16 → 5.15 (access control) | PR.DS-1 (Data-at-rest protected) | Req. 3.5 (Encryption of cardholder data) | Art. 21(2)(b) — Secure access & asset management | Art. 8 — ICT risk management (data security) |
| 2 — Centralized Logging | CloudTrail, CloudWatch, KMS | A.12.4 → 8.15 (logging), A.8.20 → 8.24 | DE.AE-1 (Anomalous activity detected) | Req. 10 (Logging & monitoring) | Art. 21(2)(d) — Event logging & monitoring | Art. 23 — Incident detection & reporting |
| 3 — Config & Conformance | Config rules, Conformance packs | A.12.1 → 5.14, A.18.2.2 → 5.36 | ID.RA-1 (Risks identified) | Req. 11.5 (File integrity monitoring) | Art. 21(2)(c) — Risk assessment & treatment | Art. 8 — ICT risk management, compliance |
| 4 — Security Hub & GuardDuty | Threat detection, incident dashboard | A.12.4 → 8.15, A.12.6 → 8.8 | DE.CM-1 (Continuous monitoring) | Req. 12.10 (Incident response) | Art. 21(2)(d) — Threat detection & response | Art. 23 — ICT incident handling, reporting |
| 5 — OPA Policy-as-Code | Terraform plan eval, CI/CD enforcement | A.12.6 → 8.8, A.18.2.2 → 5.36, A.9.2.3 → 5.18 | PR.IP-3 (Secure dev lifecycle) | Req. 6.3 (Secure development practices) | Art. 21(2)(a) — Governance & policies | Art. 8 — ICT controls automation |
| 6 — Organizations & SCPs | DenyLeaveOrg, Protect Security Services, RestrictRegions | A.5.1.1 → 5.1, A.12.4 → 8.15, A.9.2.3 → 5.18 | RS.MI-1 (Mitigation executed) | Req. 7.2 (Restrict access to cardholder data) | Art. 21(2)(b) — Access control, least privilege | Art. 8 — ICT governance; Art. 30 — Third-party/vendor risk |

---

### Legend
- **NIS2**: Art. 21 = Cybersecurity risk management (access control, monitoring, governance) | Art. 23 = Incident detection & reporting
- **DORA**: Art. 8 = ICT risk management & controls | Art. 23 = ICT incident reporting | Art. 30 = Third-party/vendor management
- **NIST CSF**: ID = Identify | PR = Protect | DE = Detect | RS = Respond | RC = Recover
- **PCI DSS**: Req. = Requirement

---

### Conclusion
This compliance mapping demonstrates how the AWS secure multi-account baseline enforces **core security controls** and aligns with both **global standards** (ISO/IEC 27001, NIST CSF, PCI DSS) and **European frameworks** (NIS2, DORA).

The result: cloud environments that are **secure, audit-ready, and trusted** for regulated industries such as **banking, financial services, government, telecom, and critical infrastructure** — fully supporting the cybersecurity priorities of the European Union.
