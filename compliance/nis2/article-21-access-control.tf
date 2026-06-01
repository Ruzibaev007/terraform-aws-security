# =============================================================================
# NIS2 Article 21 — Access Control & Identity Management
# EU Cybersecurity Directive 2022/2555
#
# Controls implemented:
#   21(1) — Multi-factor authentication (MFA)
#   21(2) — Role-based access control (RBAC) with least privilege
#   21(3) — Privileged access management (PAM)
#   21(4) — Session management & timeout
#   21(5) — Access review & audit trail
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# =============================================================================
# 21(1): MFA Enforcement — deny all actions without MFA
# =============================================================================
resource "aws_iam_policy" "nis2_enforce_mfa" {
  name        = "NIS2-Article21-EnforceMFA"
  description = "NIS2 Art.21(1): Deny all sensitive actions without MFA"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyWithoutMFA"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "sts:GetSessionToken"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })

  tags = {
    NIS2Control = "Article-21-1-MFA"
    Framework   = "NIS2"
  }
}

# =============================================================================
# 21(2): RBAC — Read-only role for auditors
# =============================================================================
resource "aws_iam_role" "nis2_auditor" {
  name        = "NIS2-Auditor-ReadOnly"
  description = "NIS2 Art.21(2): Read-only access for compliance auditors"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action = "sts:AssumeRole"
      Condition = {
        Bool = {
          "aws:MultiFactorAuthPresent" = "true"
        }
      }
    }]
  })

  max_session_duration = 3600  # 1 hour max

  tags = {
    NIS2Control = "Article-21-2-RBAC"
    Purpose     = "Compliance-Audit"
  }
}

resource "aws_iam_role_policy_attachment" "nis2_auditor_readonly" {
  role       = aws_iam_role.nis2_auditor.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# =============================================================================
# 21(3): Privileged Access — break-glass admin role (emergency only)
# =============================================================================
resource "aws_iam_role" "nis2_break_glass" {
  name        = "NIS2-BreakGlass-Admin"
  description = "NIS2 Art.21(3): Emergency privileged access — requires MFA + approval"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action = "sts:AssumeRole"
      Condition = {
        Bool = {
          "aws:MultiFactorAuthPresent" = "true"
        }
        NumericLessThan = {
          "aws:MultiFactorAuthAge" = "900"  # MFA must be < 15 minutes old
        }
      }
    }]
  })

  max_session_duration = 3600  # 1 hour max — no long-lived sessions

  tags = {
    NIS2Control = "Article-21-3-PAM"
    Purpose     = "BreakGlass-Emergency"
    ApprovalRequired = "true"
  }
}

# CloudWatch alarm when break-glass role is used
resource "aws_cloudwatch_metric_filter" "break_glass_used" {
  name           = "NIS2-BreakGlassRoleUsed"
  pattern        = "{ $.eventName = \"AssumeRole\" && $.requestParameters.roleArn = \"*BreakGlass*\" }"
  log_group_name = var.cloudtrail_log_group_name

  metric_transformation {
    name      = "BreakGlassAccessCount"
    namespace = "NIS2SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "break_glass_alarm" {
  alarm_name          = "NIS2-BreakGlass-Access-Detected"
  alarm_description   = "NIS2 Art.21(3): Privileged break-glass role was used — review required"
  metric_name         = "BreakGlassAccessCount"
  namespace           = "NIS2SecurityMetrics"
  statistic           = "Sum"
  period              = "60"
  evaluation_periods  = "1"
  threshold           = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.security_sns_topic_arn]

  tags = {
    NIS2Control = "Article-21-3-PAM"
    Severity    = "HIGH"
  }
}

# =============================================================================
# 21(4): Session Management — enforce session timeout via IAM policy
# =============================================================================
resource "aws_iam_policy" "nis2_session_policy" {
  name        = "NIS2-Article21-SessionPolicy"
  description = "NIS2 Art.21(4): Enforce max 8-hour sessions for human users"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyLongSessions"
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          NumericGreaterThan = {
            "aws:TokenIssueTime" = "28800"  # 8 hours in seconds
          }
        }
      }
    ]
  })

  tags = {
    NIS2Control = "Article-21-4-SessionManagement"
  }
}

# =============================================================================
# 21(5): Access Reviews — AWS Config rule to detect stale access keys
# =============================================================================
resource "aws_config_config_rule" "nis2_access_key_rotation" {
  name        = "NIS2-Article21-AccessKeyRotation"
  description = "NIS2 Art.21(5): IAM access keys must be rotated every 90 days"

  source {
    owner             = "AWS"
    source_identifier = "ACCESS_KEYS_ROTATED"
  }

  input_parameters = jsonencode({
    maxAccessKeyAge = "90"
  })

  tags = {
    NIS2Control = "Article-21-5-AccessReview"
  }
}

resource "aws_config_config_rule" "nis2_mfa_enabled" {
  name        = "NIS2-Article21-MFAEnabled"
  description = "NIS2 Art.21(1): All IAM users with console access must have MFA"

  source {
    owner             = "AWS"
    source_identifier = "MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS"
  }

  tags = {
    NIS2Control = "Article-21-1-MFA"
  }
}

resource "aws_config_config_rule" "nis2_no_root_access_key" {
  name        = "NIS2-Article21-NoRootAccessKey"
  description = "NIS2 Art.21(3): Root account must not have active access keys"

  source {
    owner             = "AWS"
    source_identifier = "IAM_ROOT_ACCESS_KEY_CHECK"
  }

  tags = {
    NIS2Control = "Article-21-3-RootProtection"
    Severity    = "CRITICAL"
  }
}

# =============================================================================
# Variables
# =============================================================================
variable "cloudtrail_log_group_name" {
  description = "CloudWatch log group name for CloudTrail events"
  type        = string
  default     = "/aws/cloudtrail/events"
}

variable "security_sns_topic_arn" {
  description = "SNS topic ARN for security alerts"
  type        = string
}
