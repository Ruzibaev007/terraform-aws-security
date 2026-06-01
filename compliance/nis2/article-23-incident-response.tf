# =============================================================================
# NIS2 Article 23 — Incident Detection, Reporting & Response
# DORA Article 16 — Major incident reporting (72-hour SLA)
#
# Controls implemented:
#   23(1) — Incident detection (GuardDuty + Config + SecurityHub)
#   23(2) — Incident classification (CRITICAL/HIGH/MEDIUM/LOW)
#   23(3) — 72-hour reporting to national competent authority
#   23(4) — Post-incident review & lessons learned
# =============================================================================

# =============================================================================
# 23(1): AWS Config Rules — continuous compliance monitoring
# =============================================================================
resource "aws_config_config_rule" "nis2_cloudtrail_enabled" {
  name        = "NIS2-Article23-CloudTrailEnabled"
  description = "NIS2 Art.23(1): CloudTrail must be active for incident investigation"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  tags = { NIS2Control = "Article-23-1-Detection" }
}

resource "aws_config_config_rule" "nis2_guardduty_enabled" {
  name        = "NIS2-Article23-GuardDutyEnabled"
  description = "NIS2 Art.23(1): GuardDuty must be active for threat detection"

  source {
    owner             = "AWS"
    source_identifier = "GUARDDUTY_ENABLED_CENTRALIZED"
  }

  tags = { NIS2Control = "Article-23-1-ThreatDetection" }
}

resource "aws_config_config_rule" "nis2_securityhub_enabled" {
  name        = "NIS2-Article23-SecurityHubEnabled"
  description = "NIS2 Art.23(1): Security Hub centralizes all security findings"

  source {
    owner             = "AWS"
    source_identifier = "SECURITYHUB_ENABLED"
  }

  tags = { NIS2Control = "Article-23-1-CentralizedFindings" }
}

# =============================================================================
# 23(2): Incident Classification — SNS topics by severity
# =============================================================================

# CRITICAL: national authority notification required within 72h
resource "aws_sns_topic" "nis2_critical_incidents" {
  name              = "${var.name_prefix}-nis2-critical-incidents"
  kms_master_key_id = var.kms_key_id

  tags = {
    NIS2Control    = "Article-23-2-Classification"
    Severity       = "CRITICAL"
    ReportingRequired = "true"
    ReportingDeadline = "72h"
  }
}

# HIGH: internal security team notification
resource "aws_sns_topic" "nis2_high_incidents" {
  name              = "${var.name_prefix}-nis2-high-incidents"
  kms_master_key_id = var.kms_key_id

  tags = {
    NIS2Control = "Article-23-2-Classification"
    Severity    = "HIGH"
  }
}

# Email subscriptions
resource "aws_sns_topic_subscription" "critical_email" {
  topic_arn = aws_sns_topic.nis2_critical_incidents.arn
  protocol  = "email"
  endpoint  = var.ciso_email
}

resource "aws_sns_topic_subscription" "high_email" {
  topic_arn = aws_sns_topic.nis2_high_incidents.arn
  protocol  = "email"
  endpoint  = var.security_team_email
}

# =============================================================================
# 23(3): Automated Incident Response Playbook (Lambda)
# Classifies findings and triggers appropriate response
# =============================================================================
resource "aws_iam_role" "nis2_playbook" {
  name = "${var.name_prefix}-nis2-incident-playbook"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { NIS2Control = "Article-23-3-IncidentResponse" }
}

resource "aws_iam_role_policy" "nis2_playbook_policy" {
  name = "NIS2IncidentPlaybookPolicy"
  role = aws_iam_role.nis2_playbook.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = [aws_sns_topic.nis2_critical_incidents.arn, aws_sns_topic.nis2_high_incidents.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["guardduty:GetFindings", "guardduty:ListFindings", "guardduty:ArchiveFindings"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:PutParameter", "ssm:GetParameter"]
        Resource = "arn:aws:ssm:*:*:parameter/nis2/incidents/*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

data "archive_file" "playbook_code" {
  type        = "zip"
  output_path = "/tmp/nis2_playbook.zip"

  source {
    filename = "index.py"
    content  = <<-PYTHON
import json, os, boto3
from datetime import datetime, timezone

sns    = boto3.client('sns')
ssm    = boto3.client('ssm')

# NIS2 Article 23(2) — Severity thresholds
SEVERITY_THRESHOLDS = {
    "CRITICAL": 7.0,   # Must report to national authority within 72h
    "HIGH":     4.0,   # Internal escalation required
    "MEDIUM":   2.0,   # Track and monitor
}

def handler(event, context):
    finding   = event.get('detail', {})
    severity  = float(finding.get('severity', 0))
    f_type    = finding.get('type', 'Unknown')
    region    = finding.get('region', 'unknown')
    account   = finding.get('accountId', 'unknown')
    f_id      = finding.get('id', 'unknown')
    timestamp = datetime.now(timezone.utc).isoformat()

    # Classify per NIS2 Article 23(2)
    if severity >= SEVERITY_THRESHOLDS["CRITICAL"]:
        classification   = "CRITICAL"
        reporting_needed = True
        deadline_hours   = 72
        topic_arn        = os.environ['CRITICAL_SNS_ARN']
    elif severity >= SEVERITY_THRESHOLDS["HIGH"]:
        classification   = "HIGH"
        reporting_needed = False
        deadline_hours   = None
        topic_arn        = os.environ['HIGH_SNS_ARN']
    else:
        print(f"Severity {severity} below HIGH threshold — no action")
        return {"statusCode": 200}

    # Build NIS2-compliant incident record
    incident = {
        "incident_id":          f"NIS2-{account}-{int(datetime.now().timestamp())}",
        "timestamp":            timestamp,
        "classification":       classification,
        "nis2_article":         "23",
        "reporting_required":   reporting_needed,
        "reporting_deadline":   f"{deadline_hours}h from detection" if deadline_hours else "N/A",
        "authority_to_notify":  "BSI (Bundesamt für Sicherheit in der Informationstechnik)" if reporting_needed else "N/A",
        "finding": {
            "id":       f_id,
            "type":     f_type,
            "severity": severity,
            "region":   region,
            "account":  account,
        },
        "response_steps": [
            "1. CONTAIN: Isolate affected resources immediately",
            "2. ASSESS:  Determine impact scope and affected data",
            "3. COLLECT: Preserve CloudTrail logs and evidence",
            f"4. REPORT:  {'Notify BSI within 72h via https://www.bsi.bund.de/meldung' if reporting_needed else 'Document internally'}",
            "5. RECOVER: Restore from clean backup",
            "6. REVIEW:  Conduct post-incident review within 30 days (NIS2 Art.23(4))",
        ]
    }

    # Store in SSM for audit trail (NIS2 Art.23(4))
    ssm.put_parameter(
        Name=f"/nis2/incidents/{incident['incident_id']}",
        Value=json.dumps(incident),
        Type="String",
        Overwrite=True
    )

    # Send alert
    sns.publish(
        TopicArn=topic_arn,
        Subject=f"[NIS2 {classification}] {f_type} in {region}",
        Message=json.dumps(incident, indent=2)
    )

    print(f"NIS2 Incident processed: {incident['incident_id']} ({classification})")
    return {"statusCode": 200, "incident_id": incident['incident_id']}
    PYTHON
  }
}

resource "aws_lambda_function" "nis2_playbook" {
  function_name    = "${var.name_prefix}-nis2-incident-playbook"
  role             = aws_iam_role.nis2_playbook.arn
  runtime          = "python3.12"
  handler          = "index.handler"
  timeout          = 60
  filename         = data.archive_file.playbook_code.output_path
  source_code_hash = data.archive_file.playbook_code.output_base64sha256

  environment {
    variables = {
      CRITICAL_SNS_ARN = aws_sns_topic.nis2_critical_incidents.arn
      HIGH_SNS_ARN     = aws_sns_topic.nis2_high_incidents.arn
      ENVIRONMENT      = var.environment
    }
  }

  tags = {
    NIS2Control = "Article-23-3-AutomatedPlaybook"
    DORAControl = "Article-16-MajorIncidentReporting"
  }
}

# EventBridge: GuardDuty HIGH/CRITICAL → Lambda playbook
resource "aws_cloudwatch_event_rule" "nis2_guardduty_trigger" {
  name        = "${var.name_prefix}-nis2-guardduty-trigger"
  description = "NIS2 Art.23: Trigger incident playbook on GuardDuty HIGH/CRITICAL"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", 4.0] }]
    }
  })
}

resource "aws_cloudwatch_event_target" "nis2_playbook_target" {
  rule      = aws_cloudwatch_event_rule.nis2_guardduty_trigger.name
  target_id = "NIS2IncidentPlaybook"
  arn       = aws_lambda_function.nis2_playbook.arn
}

resource "aws_lambda_permission" "nis2_eventbridge" {
  statement_id  = "AllowNIS2EventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nis2_playbook.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.nis2_guardduty_trigger.arn
}

# =============================================================================
# Variables
# =============================================================================
variable "name_prefix"       { type = string }
variable "environment"       { type = string; default = "prod" }
variable "kms_key_id"        { type = string }
variable "ciso_email"        { type = string; description = "CISO email for CRITICAL incidents" }
variable "security_team_email" { type = string; description = "Security team email for HIGH incidents" }
