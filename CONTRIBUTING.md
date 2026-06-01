# Contributing to terraform-aws-security

Thank you for contributing! This project implements **NIS2, DORA, and ISO 27001** compliance as Terraform code.

## Quick Start

```bash
git clone https://github.com/Protector080322/terraform-aws-security
cd terraform-aws-security
cp examples/mittelstand-sme/terraform.tfvars .
terraform init && terraform plan
```

## What We Accept

- ✅ New compliance controls (NIS2 articles, DORA, ISO 27001, BSI)
- ✅ New industry examples (finance, energy, transport)
- ✅ Improved OPA policies
- ✅ Bug fixes and documentation
- ✅ New Kubernetes security patterns

## Code Standards

```bash
# Before submitting PR:
terraform fmt -recursive      # Format code
opa test policies-as-code/opa/ -v    # Run OPA tests
./scripts/validate-compliance.sh     # Full compliance check
```

## Pull Request Checklist

- [ ] `terraform fmt` applied
- [ ] OPA tests pass
- [ ] NIS2/DORA article referenced in comments
- [ ] Tags include `NIS2Control` or `DORAControl`
- [ ] `docs/compliance-mapping.md` updated

## NIS2 Coding Convention

```hcl
# Every resource must reference the NIS2 article it implements
resource "aws_iam_policy" "example" {
  name        = "NIS2-Article21-Example"
  description = "NIS2 Art.21(1): Description of control"

  tags = {
    NIS2Control = "Article-21-1-MFA"     # Required
    Framework   = "NIS2"                  # Required
    Severity    = "CRITICAL|HIGH|MEDIUM"  # Required
  }
}
```

## Contact

Questions? Open a [GitHub Issue](https://github.com/Protector080322/terraform-aws-security/issues) or email: security@cybercheck-infra.de
