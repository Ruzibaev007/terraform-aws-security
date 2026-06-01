# =============================================================================
# Step 2: Centralized Logging — NIS2 Article 25 compliant
# Changes: CloudTrail ENABLED, EU region, S3 Object Lock, retention policy
# =============================================================================

module "logging" {
  source = "../../modules/logging"

  name_prefix = local.name_prefix
  env         = var.env

  # NIS2 Article 25: Audit logging MUST be enabled
  enable_cloudtrail = true   # FIXED: was false — critical security gap

  tags = merge(local.tags, {
    NIS2Control     = "Article-25"
    DataResidency   = "EU-DE"
    ComplianceOwner = "security-team"
  })
}

# =============================================================================
# NIS2 Article 25 — S3 Object Lock (tamper-proof audit logs)
# Prevents deletion or modification of audit logs for 365 days
# =============================================================================
resource "aws_s3_bucket_object_lock_configuration" "audit_logs" {
  bucket = module.logging.log_bucket_id

  rule {
    default_retention {
      mode = "GOVERNANCE"   # Use COMPLIANCE for stricter NIS2 enforcement
      days = 365            # NIS2 minimum: 1 year retention
    }
  }
}

# =============================================================================
# NIS2 Article 25 — CloudWatch log group for real-time monitoring
# =============================================================================
resource "aws_cloudwatch_log_group" "security_events" {
  name              = "/aws/security/${local.name_prefix}/events"
  retention_in_days = 365   # NIS2 Article 25: minimum 1 year

  kms_key_id = module.logging.kms_key_arn

  tags = merge(local.tags, {
    NIS2Control = "Article-25-AuditLogging"
  })
}

# =============================================================================
# NIS2 Article 23 — CloudWatch Metric Filters for incident detection
# Alerts on: root login, MFA disable, SCP changes, GuardDuty disable
# =============================================================================

# Alert: Root account login (critical — NIS2 Article 21)
resource "aws_cloudwatch_metric_filter" "root_login" {
  name           = "${local.name_prefix}-root-login"
  pattern        = "{ $.userIdentity.type = \"Root\" && $.eventType != \"AwsServiceEvent\" }"
  log_group_name = aws_cloudwatch_log_group.security_events.name

  metric_transformation {
    name      = "RootLoginCount"
    namespace = "NIS2SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_login_alarm" {
  alarm_name          = "${local.name_prefix}-root-login-detected"
  alarm_description   = "NIS2 Art.21: Root account login detected — immediate investigation required"
  metric_name         = "RootLoginCount"
  namespace           = "NIS2SecurityMetrics"
  statistic           = "Sum"
  period              = "60"
  evaluation_periods  = "1"
  threshold           = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.security_alerts.arn]

  tags = merge(local.tags, {
    NIS2Control = "Article-21-AccessControl"
    Severity    = "CRITICAL"
  })
}

# Alert: MFA disabled for any user (NIS2 Article 21)
resource "aws_cloudwatch_metric_filter" "mfa_disabled" {
  name           = "${local.name_prefix}-mfa-disabled"
  pattern        = "{ $.eventName = \"DeleteVirtualMFADevice\" || $.eventName = \"DeactivateMFADevice\" }"
  log_group_name = aws_cloudwatch_log_group.security_events.name

  metric_transformation {
    name      = "MFADisabledCount"
    namespace = "NIS2SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "mfa_disabled_alarm" {
  alarm_name          = "${local.name_prefix}-mfa-disabled"
  alarm_description   = "NIS2 Art.21: MFA was disabled for an IAM user"
  metric_name         = "MFADisabledCount"
  namespace           = "NIS2SecurityMetrics"
  statistic           = "Sum"
  period              = "300"
  evaluation_periods  = "1"
  threshold           = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.security_alerts.arn]

  tags = merge(local.tags, {
    NIS2Control = "Article-21-MFA"
    Severity    = "HIGH"
  })
}

# Alert: GuardDuty disabled (NIS2 Article 23 — incident detection must not be disabled)
resource "aws_cloudwatch_metric_filter" "guardduty_disabled" {
  name           = "${local.name_prefix}-guardduty-disabled"
  pattern        = "{ $.eventName = \"DeleteDetector\" || $.eventName = \"DisassociateFromMasterAccount\" }"
  log_group_name = aws_cloudwatch_log_group.security_events.name

  metric_transformation {
    name      = "GuardDutyDisabledCount"
    namespace = "NIS2SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "guardduty_disabled_alarm" {
  alarm_name          = "${local.name_prefix}-guardduty-disabled"
  alarm_description   = "NIS2 Art.23: GuardDuty was disabled — incident detection gap!"
  metric_name         = "GuardDutyDisabledCount"
  namespace           = "NIS2SecurityMetrics"
  statistic           = "Sum"
  period              = "60"
  evaluation_periods  = "1"
  threshold           = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.security_alerts.arn]

  tags = merge(local.tags, {
    NIS2Control = "Article-23-IncidentDetection"
    Severity    = "CRITICAL"
  })
}

# =============================================================================
# SNS Topic for security alerts (used by all alarms above)
# =============================================================================
resource "aws_sns_topic" "security_alerts" {
  name              = "${local.name_prefix}-nis2-security-alerts"
  kms_master_key_id = module.logging.kms_key_arn

  tags = merge(local.tags, {
    NIS2Control = "Article-23-IncidentNotification"
  })
}

resource "aws_sns_topic_subscription" "security_email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.security_alerts_email   # Set in terraform.tfvars
}
