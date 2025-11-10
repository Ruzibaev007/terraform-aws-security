package terraform.security
import data.terraform.lib

# --- Security Hub present? ---
exists_securityhub {
  some i
  r := input.resource_changes[i]
  r.type == "aws_securityhub_account"
  lib.has_after(r)
}

# --- GuardDuty present & enabled? ---
exists_guardduty {
  some i
  r := input.resource_changes[i]
  r.type == "aws_guardduty_detector"
  lib.has_after(r)
  lib.get_after(r).enable
}

missing_securityhub { not exists_securityhub }
missing_guardduty   { not exists_guardduty }

deny[msg] {
  missing_securityhub
  msg := "Security Hub is not enabled in plan."
}

deny[msg] {
  missing_guardduty
  msg := "GuardDuty is not enabled in plan."
}
