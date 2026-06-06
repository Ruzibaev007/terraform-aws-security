[![NIS2/DORA CI](https://github.com/Ruzibaev007/terraform-aws-security/actions/workflows/plan.yml/badge.svg)](https://github.com/Ruzibaev007/terraform-aws-security/actions/workflows/plan.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![NIS2 Compliant](https://img.shields.io/badge/NIS2-Compliant-blue?logo=eu)](compliance/nis2/README.md)
[![DORA Ready](https://img.shields.io/badge/DORA-Ready-orange)](compliance/dora/README.md)
[![ISO 27001](https://img.shields.io/badge/ISO%2027001-Mapped-brightgreen)](docs/compliance-mapping.md)
[![Terraform](https://img.shields.io/badge/Terraform-≥1.5-7B42BC?logo=terraform)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-Multi--Account-FF9900?logo=amazonaws)](https://aws.amazon.com)
[![BSI IT-Grundschutz](https://img.shields.io/badge/BSI-IT--Grundschutz-003366)](docs/compliance-mapping.md)

# 🔐 terraform-aws-security

> **Production-ready AWS security baseline for the EU — NIS2, DORA, ISO 27001, BSI IT-Grundschutz.**
>
> The only open-source Terraform framework that covers **NIS2 Articles 21–32**, **DORA Article 16**, and **BSI IT-Grundschutz** out of the box — built for German Mittelstand and EU critical infrastructure.

🇩🇪 **[Deutsche Version](#deutsch)** | 🇬🇧 **[English Version](#english)**

---

## English

### ⚡ 5-Minute Quick Start

```bash
# Prerequisites: terraform >= 1.5, aws-cli >= 2.13, opa >= 0.68
bash install/linux.sh     # Linux / Linux Mint
bash install/macos.sh     # macOS
# Windows: .\install\windows.ps1

# Deploy
git clone https://github.com/Protector080322/terraform-aws-security
cd terraform-aws-security
cp examples/mittelstand-sme/terraform.tfvars .
make validate             # NIS2/DORA compliance check
make plan                 # Preview changes
make apply                # Deploy (requires confirmation)
```

### 🎯 Who Is This For?

| You are... | This gives you... |
|---|---|
| **German Mittelstand IT team** | NIS2-compliant AWS baseline in under 1 hour |
| **Security Architect (EU)** | 35+ controls mapped to NIS2/DORA/ISO 27001 |
| **vCISO / Compliance Lead** | Automated evidence generation & BSI-ready reports |
| **DevOps Engineer** | Policy-as-Code pipeline blocking non-compliant deploys |
| **Auditor / Pen Tester** | Ready-made OPA policies for infrastructure review |

### 🏆 Why This Project?

**The problem:** NIS2 became mandatory in Germany in October 2024. DORA in January 2025. Most AWS environments are NOT compliant. Manual compliance is expensive, slow, and error-prone.

**The solution:** Infrastructure-as-Code + Policy-as-Code = compliance at the speed of deployment.

```
Traditional compliance:  manual audit → 3 months → €50k+
This framework:          terraform apply → 5 minutes → automated evidence
```

### 📊 Compliance Frameworks

| Framework | Articles | Status | Who Needs It |
|---|---|---|---|
| 🇪🇺 **NIS2** (EU 2022/2555) | 21, 23, 25, 28, 32 | ✅ Full | All EU essential/important operators |
| 🏦 **DORA** (EU 2022/2554) | 16 (incident reporting) | ✅ Implemented | Banks, insurance, investment firms |
| 📋 **ISO 27001:2022** | A.5–A.18 (35+ controls) | ✅ Mapped | Any security-conscious organization |
| 🇩🇪 **BSI IT-Grundschutz** | ORP.4, CON.1, DER.2.1, NET.1.1 | ✅ Aligned | German organizations |
| 🔒 **GDPR** | Data residency (EU-DE) | ✅ Configured | All EU data processors |
| 🚗 **TISAX** | VDA ISA 6.0 | ✅ Example | Automotive suppliers |

### 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   AWS Organization                       │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │  Management │  │ Production  │  │  Audit Account  │ │
│  │  Account    │  │  Account    │  │                 │ │
│  │  SCPs       │  │  EKS/k3s    │  │  CloudTrail     │ │
│  │  GuardDuty  │  │  RDS (enc.) │  │  S3 (locked)    │ │
│  │  SecurityHub│  │  VPC        │  │  KMS            │ │
│  └─────────────┘  └─────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────┘
         │                   │                   │
    NIS2 Art.21         NIS2 Art.32         NIS2 Art.25
    (Access Control)  (Network Security)  (Audit Logging)
```

See [ARCHITECTURE.md](./ARCHITECTURE.md) for full Mermaid diagrams.

### 🔒 Security Controls (35+)

<details>
<summary><b>NIS2 Article 21 — Access Control</b></summary>

- MFA enforcement (deny all actions without MFA)
- Permission boundaries on all IAM roles/users
- Break-glass PAM role (emergency access, 15-min MFA window)
- Session timeout: 8 hours maximum
- Access key rotation: 90-day AWS Config rule
- No root access key (Config rule)
- RBAC: auditor read-only role

</details>

<details>
<summary><b>NIS2 Article 23 — Incident Detection & Response</b></summary>

- GuardDuty (ML-based threat detection, EKS audit logs)
- Security Hub (CIS 1.4.0 + AFSBP + NIST centralized findings)
- Lambda incident response playbook (auto-classifies, notifies BSI)
- EventBridge: GuardDuty HIGH/CRITICAL → Lambda → SNS
- CloudWatch alarms: root login, MFA disable, GuardDuty disable
- DORA Step Functions: 4h → 72h → 1-month BaFin reporting

</details>

<details>
<summary><b>NIS2 Article 25 — Audit Logging & Encryption</b></summary>

- CloudTrail: multi-region, log file validation, KMS encrypted
- S3 Object Lock: tamper-proof logs, GOVERNANCE mode, 365 days
- S3 lifecycle: STANDARD_IA (90d) → Glacier (365d) → delete (7yr)
- KMS: dedicated key, automatic annual rotation
- All S3 buckets: KMS encryption (not AES256)
- RDS: encrypted storage (Config rule)
- EBS: encrypted volumes (Config rule)

</details>

<details>
<summary><b>NIS2 Article 28 — Supply Chain & Data Residency</b></summary>

- EU-only regions: eu-central-1 (Frankfurt) + eu-west-1 (Ireland)
- Terraform variable validation: `startswith(var.region, "eu-")`
- SCP: deny CloudTrail disable
- SCP: deny GuardDuty disable
- SCP: deny Security Hub disable
- SCP: deny S3 public access

</details>

<details>
<summary><b>NIS2 Article 32 — Network Segmentation</b></summary>

- k3s NetworkPolicies: default-deny-ingress
- IMDSv2 required on all EC2 (SSRF protection)
- No public IPs on backend instances
- VPC flow logs (Config rule)
- Lambda in VPC (Config rule)
- SSH/RDP blocked from internet (OPA rule)

</details>

### 🚀 What's Inside

```
terraform-aws-security/
├── 📁 envs/
│   ├── dev/           # 7-step deployment (state→logging→config→security→pac→scps→iam)
│   └── prod/          # Production mirror
├── 📁 modules/
│   ├── logging/       # CloudTrail + KMS + S3
│   ├── iam/           # Permission boundaries + MFA
│   ├── config/        # AWS Config + conformance packs
│   └── org/scps/      # Organization SCPs
├── 📁 compliance/
│   ├── nis2/          # Articles 21, 23, 25 (Terraform)
│   └── dora/          # Article 16 Step Functions workflow
├── 📁 examples/
│   ├── mittelstand-sme/  # German manufacturing, ~500 employees
│   ├── healthcare/       # GDPR Art.9 + NIS2 essential
│   └── automotive/       # TISAX + ISO-SAE-21434
├── 📁 kubernetes/
│   └── k3s-hardened/     # NIS2 Art.21/32 hardened cluster
├── 📁 policies-as-code/
│   └── opa/              # 20+ NIS2/DORA/ISO 27001 OPA rules
├── 📁 install/
│   ├── macos.sh          # One-command setup for macOS
│   ├── linux.sh          # One-command setup for Linux
│   └── windows.ps1       # One-command setup for Windows
├── 📁 scripts/
│   ├── validate-compliance.sh  # Pre-deploy check
│   └── generate-report.sh      # Compliance report generator
├── 📁 docs/
│   └── compliance-mapping.md   # 35+ controls mapped
├── Makefile              # make validate / plan / apply / report
├── ARCHITECTURE.md       # 7 Mermaid diagrams
├── GETTING_STARTED.md    # 5-minute setup guide
└── CHANGELOG.md          # Version history
```

### 📈 CI/CD Pipeline

Every pull request runs:

```
terraform fmt → terraform validate
       ↓
  tfsec (HIGH+)  →  checkov
       ↓
  OPA unit tests → OPA plan eval
       ↓
  gitleaks (secrets scan)
       ↓
  terraform plan (with OPA validation)
       ↓
  compliance report
       ↓
  terraform apply (main branch only, after approval)
```

### 🏭 Industry Examples

```bash
# German Mittelstand (manufacturing, ~500 employees)
cp examples/mittelstand-sme/terraform.tfvars .

# Healthcare (GDPR Art.9 + NIS2 essential operator)
cp examples/healthcare/terraform.tfvars .

# Automotive (TISAX + VDA ISA 6.0 + NIS2)
cp examples/automotive/terraform.tfvars .
```

### 📚 Documentation

- [GETTING_STARTED.md](./GETTING_STARTED.md) — 5-minute quick start
- [ARCHITECTURE.md](./ARCHITECTURE.md) — Diagrams & topology
- [compliance/nis2/README.md](./compliance/nis2/README.md) — NIS2 guide
- [compliance/dora/README.md](./compliance/dora/README.md) — DORA guide
- [docs/compliance-mapping.md](./docs/compliance-mapping.md) — Control mapping
- [install/README.md](./install/README.md) — OS-specific setup

---

## Deutsch

### ⚡ 5-Minuten Schnellstart

```bash
# Voraussetzungen: terraform >= 1.5, aws-cli >= 2.13
bash install/linux.sh     # Linux / Linux Mint
bash install/macos.sh     # macOS

# Deployment
git clone https://github.com/Protector080322/terraform-aws-security
cd terraform-aws-security
cp examples/mittelstand-sme/terraform.tfvars .
make validate             # NIS2/DORA Compliance-Prüfung
make plan && make apply   # Infrastruktur deployen
```

### 🎯 Warum dieses Projekt?

**Das Problem:** Die NIS2-Richtlinie ist seit Oktober 2024 in Deutschland verbindlich. DORA seit Januar 2025. Die meisten AWS-Umgebungen sind **nicht konform**. Manuelle Compliance kostet Zeit und Geld.

**Die Lösung:** Infrastructure-as-Code + Policy-as-Code = Compliance mit jedem Deployment automatisch sichergestellt.

### 🇩🇪 BSI IT-Grundschutz Mapping

| BSI-Baustein | Beschreibung | Implementierung |
|---|---|---|
| ORP.4 | Identitäts- & Zugriffsmanagement | `modules/iam/` |
| CON.1 | Kryptokonzept | `modules/logging/` (KMS) |
| OPS.1.1.5 | Datensicherung | AWS Backup + S3 Object Lock |
| DER.2.1 | Incident Management | `compliance/nis2/article-23-incident-response.tf` |
| NET.1.1 | Netzarchitektur | `kubernetes/k3s-hardened/` |
| INF.14 | Automatisierungsnetze | `compliance/nis2/article-32-network-security.tf` |

### ⚖️ NIS2 Meldepflichten (BSI)

| Vorfall | Frist | Behörde |
|---|---|---|
| Erheblicher Sicherheitsvorfall | **24 Stunden** (Erstmeldung) | BSI |
| Vollständige Meldung | **72 Stunden** | BSI |
| Abschlussbericht | **1 Monat** | BSI |
| **BSI Meldung:** | | https://www.bsi.bund.de|

### 💰 Zielgruppen in Deutschland

- **Mittelstand** (Fertigung, Maschinenbau, Automobilzulieferer)
- **Gesundheitswesen** (Krankenhäuser, Pharmaunternehmen)
- **Finanzsektor** (DORA-pflichtige Unternehmen)
- **Kritische Infrastruktur** (KRITIS-Betreiber)
- **IT-Dienstleister** für die oben genannten

---

## 🤝 Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) — we welcome:
- New NIS2/DORA article implementations
- Additional industry examples (energy, finance, healthcare)
- Improved OPA policies
- Bug fixes and documentation

## 📜 License

MIT License — free to use, modify, and distribute.

## 👤 Maintainer

**[Protector080322](https://github.com/Ruzibaev007)**
Berlin, Germany | Security Architect | NIS2 | AWS | Terraform

📧 z.ruzibaev@mail.de
🔗 [GitHub](https://github.com/Ruzibaev007/terraform-aws-security)

---

*Built for German Mittelstand. Compliant with EU regulations. Open source.*
