# DORA Compliance Implementation

> **Digital Operational Resilience Act** (EU) 2022/2554 — mandatory for EU financial entities from January 2025.

## Who Needs DORA?

Banks, insurance companies, investment firms, crypto-asset providers, payment institutions, and their ICT third-party providers operating in the EU.

## Articles Covered

| Article | Topic | File | Status |
|---------|-------|------|--------|
| **Art. 6** | ICT Risk Management | `article-6-ict-risk.tf` | 🚧 |
| **Art. 16** | Incident Reporting | `article-16-incident-reporting.tf` | ✅ |
| **Art. 17** | Incident Classification | Included in Art.16 | ✅ |
| **Art. 25** | Threat Intelligence | `article-25-threat-intel.tf` | 🚧 |

## Reporting Deadlines

| Report | Deadline | Authority (Germany) |
|--------|----------|-------------------|
| Initial notification | **4 hours** | BaFin |
| Intermediate report | **72 hours** | BaFin |
| Final report | **1 month** | BaFin |
| BaFin portal | | https://www.bafin.de/meldungen |

## Quick Start

```bash
cd compliance/dora
terraform init
terraform apply -target=aws_sfn_state_machine.dora_incident_workflow
```
