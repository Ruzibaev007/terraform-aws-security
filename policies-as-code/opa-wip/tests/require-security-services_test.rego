package terraform.security_test
import data.terraform.security as policy

empty_plan := {"resource_changes": []}

test_deny_when_securityhub_missing {
  res := policy.deny with input as empty_plan
  some m
  m := res[_]
  m == "Security Hub is not enabled in plan."
}

test_deny_when_guardduty_missing {
  plan := {
    "resource_changes": [
      {"type": "aws_securityhub_account", "change": {"after": {}, "actions": ["create"]}}
    ]
  }
  res := policy.deny with input as plan
  some m
  m := res[_]
  m == "GuardDuty is not enabled in plan."
}

test_ok_when_both_present {
  plan := {
    "resource_changes": [
      {"type": "aws_securityhub_account", "change": {"after": {}, "actions": ["create"]}},
      {"type": "aws_guardduty_detector", "change": {"after": {"enable": true}, "actions": ["create"]}}
    ]
  }
  res := policy.deny with input as plan
  count(res) == 0
}


test_deny_when_both_missing {
  res := {m | m := policy.deny[_]} with input as {"resource_changes": []}
  res == {
    "Security Hub is not enabled in plan.",
    "GuardDuty is not enabled in plan."
  }
}
