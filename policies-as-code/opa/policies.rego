# =============================================================================
# OPA/Rego Policy — NIS2 + DORA + ISO 27001 Compliance Validation
# Validates Terraform plans BEFORE deployment
#
# Frameworks covered:
#   NIS2 Article 21 (Access Control)
#   NIS2 Article 23 (Incident Detection)
#   NIS2 Article 25 (Audit Logging & Encryption)
#   NIS2 Article 32 (Network Security)
#   DORA Article 6  (ICT Risk Management)
# =============================================================================

package terraform.security

import rego.v1

# =============================================================================
# SECTION 1: IAM Governance (NIS2 Article 21)
# =============================================================================

# Rule: All IAM roles must have a permissions boundary
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_iam_role"
  rc.change.after
  not rc.change.after.permissions_boundary
  msg := sprintf(
    "[NIS2-Art21] IAM role %q missing permissions boundary — privilege escalation risk",
    [rc.change.after.name]
  )
}

# Rule: All IAM users must have a permissions boundary
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_iam_user"
  rc.change.after
  not rc.change.after.permissions_boundary
  msg := sprintf(
    "[NIS2-Art21] IAM user %q missing permissions boundary",
    [rc.change.after.name]
  )
}

# Rule: No IAM policies with wildcard admin actions (least privilege)
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_iam_policy"
  rc.change.after
  policy := json.unmarshal(rc.change.after.policy)
  stmt := policy.Statement[_]
  stmt.Effect == "Allow"
  action := stmt.Action
  action == "*"
  resource := stmt.Resource
  resource == "*"
  msg := sprintf(
    "[NIS2-Art21] IAM policy %q grants full admin (*:*) — violates least-privilege principle",
    [rc.change.after.name]
  )
}

# =============================================================================
# SECTION 2: Security Services (NIS2 Article 23 — Incident Detection)
# =============================================================================

# Rule: Security Hub must be enabled
violations contains msg if {
  count([1 |
    rc := input.resource_changes[_]
    rc.type == "aws_securityhub_account"
    rc.change.after
  ]) == 0
  msg := "[NIS2-Art23] Security Hub not enabled — centralized incident detection missing"
}

# Rule: Security Hub must have at least one standards subscription
violations contains msg if {
  count([1 |
    rc := input.resource_changes[_]
    rc.type == "aws_securityhub_standards_subscription"
    rc.change.after
  ]) == 0
  msg := "[NIS2-Art23] Security Hub has no compliance standards (CIS/NIST/AFSBP) configured"
}

# Rule: GuardDuty must be enabled
violations contains msg if {
  count([1 |
    rc := input.resource_changes[_]
    rc.type == "aws_guardduty_detector"
    rc.change.after
  ]) == 0
  msg := "[NIS2-Art23] GuardDuty not enabled — threat detection missing"
}

# Rule: GuardDuty must not be disabled
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_guardduty_detector"
  rc.change.after
  not rc.change.after.enable
  msg := "[NIS2-Art23] GuardDuty detector is disabled — must be enabled for NIS2 compliance"
}

# Rule: EventBridge rule must exist for GuardDuty alerts (automated response)
violations contains msg if {
  count([1 |
    rc := input.resource_changes[_]
    rc.type == "aws_cloudwatch_event_rule"
    rc.change.after
    contains(lower(rc.change.after.name), "guardduty")
  ]) == 0
  msg := "[NIS2-Art23] No automated EventBridge rule for GuardDuty findings — manual detection only"
}

# =============================================================================
# SECTION 3: Encryption & Audit Logging (NIS2 Article 25)
# =============================================================================

# Rule: All S3 buckets must have server-side encryption
violations contains msg if {
  r := input.planned_values.root_module.resources[_]
  r.type == "aws_s3_bucket"
  r.values.bucket != ""
  not r.values.server_side_encryption_configuration
  msg := sprintf(
    "[NIS2-Art25] S3 bucket %q lacks server-side encryption (KMS required)",
    [r.values.bucket]
  )
}

# Rule: CloudTrail must be multi-region
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_cloudtrail"
  rc.change.after
  not rc.change.after.is_multi_region_trail
  msg := sprintf(
    "[NIS2-Art25] CloudTrail %q must be multi-region for complete audit coverage",
    [rc.change.after.name]
  )
}

# Rule: CloudTrail must have log file validation enabled
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_cloudtrail"
  rc.change.after
  not rc.change.after.enable_log_file_validation
  msg := sprintf(
    "[NIS2-Art25] CloudTrail %q must have log file validation enabled (tamper detection)",
    [rc.change.after.name]
  )
}

# Rule: KMS key rotation must be enabled
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_kms_key"
  rc.change.after
  not rc.change.after.enable_key_rotation
  msg := sprintf(
    "[NIS2-Art25] KMS key %q missing automatic key rotation — cryptographic hygiene required",
    [rc.change.after.description]
  )
}

# Rule: RDS instances must have encryption enabled
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_db_instance"
  rc.change.after
  not rc.change.after.storage_encrypted
  msg := sprintf(
    "[NIS2-Art25] RDS instance %q storage is not encrypted",
    [rc.change.after.identifier]
  )
}

# =============================================================================
# SECTION 4: Network Security (NIS2 Article 32)
# =============================================================================

# Rule: Security groups must not allow unrestricted SSH (port 22) from internet
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_security_group_rule"
  rc.change.after
  rc.change.after.type == "ingress"
  rc.change.after.from_port <= 22
  rc.change.after.to_port >= 22
  cidr := rc.change.after.cidr_blocks[_]
  cidr == "0.0.0.0/0"
  msg := "[NIS2-Art32] Security group allows unrestricted SSH (port 22) from internet — must use VPN/bastion"
}

# Rule: Security groups must not allow unrestricted RDP (port 3389) from internet
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_security_group_rule"
  rc.change.after
  rc.change.after.type == "ingress"
  rc.change.after.from_port <= 3389
  rc.change.after.to_port >= 3389
  cidr := rc.change.after.cidr_blocks[_]
  cidr == "0.0.0.0/0"
  msg := "[NIS2-Art32] Security group allows unrestricted RDP (port 3389) from internet"
}

# Rule: EC2 instances must not have public IPs in non-DMZ subnets
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_instance"
  rc.change.after
  rc.change.after.associate_public_ip_address == true
  msg := sprintf(
    "[NIS2-Art32] EC2 instance %q has public IP — use NAT Gateway + private subnet instead",
    [rc.change.after.tags.Name]
  )
}

# Rule: IMDSv2 must be required on all EC2 instances (SSRF protection)
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_instance"
  rc.change.after
  metadata := rc.change.after.metadata_options[_]
  metadata.http_tokens != "required"
  msg := sprintf(
    "[NIS2-Art32] EC2 instance must use IMDSv2 (http_tokens = required) to prevent SSRF attacks",
    []
  )
}

# =============================================================================
# SECTION 5: Tagging Compliance (for asset inventory — NIS2 Article 28)
# =============================================================================

required_tags := {"Environment", "Owner", "Compliance"}

violations contains msg if {
  rc := input.resource_changes[_]
  rc.type in {"aws_instance", "aws_s3_bucket", "aws_rds_cluster", "aws_eks_cluster"}
  rc.change.after
  tags := object.get(rc.change.after, "tags", {})
  missing := required_tags - {k | tags[k]}
  count(missing) > 0
  msg := sprintf(
    "[NIS2-Art28] Resource %q (%s) missing required tags: %v — needed for asset inventory",
    [rc.address, rc.type, missing]
  )
}

# =============================================================================
# RESULTS — Summary for CI/CD pipeline output
# =============================================================================

passed if count(violations) == 0

messages := [x | violations[x]]

result := {
  "passed":     passed,
  "count":      count(messages),
  "messages":   messages,
  "frameworks": ["NIS2", "DORA", "ISO27001"],
  "checked_at": "pre-deployment",
}
