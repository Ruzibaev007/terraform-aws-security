# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| main branch | ✅ Active |
| v2.x | ✅ Active |
| v1.x | ❌ EOL |

## Reporting a Vulnerability

**Do NOT open a public GitHub issue for security vulnerabilities.**

Email: security@cybercheck-infra.de

We respond within **24 hours** (NIS2 Art.23 commitment).

## Scope

This project deploys AWS security infrastructure. Report:
- IAM privilege escalation paths in Terraform code
- OPA policy bypasses
- Insecure default configurations
- Exposed secrets or credentials in code

## Response Timeline

| Severity | Response | Fix |
|----------|----------|-----|
| CRITICAL | 4 hours | 24 hours |
| HIGH | 24 hours | 7 days |
| MEDIUM | 72 hours | 30 days |

*Timelines align with NIS2 Article 23 incident response requirements.*
