# =============================================================================
# modules/waf/main.tf — AWS WAF v2
# NIS2 Article 32: Network Security — protect against web attacks
# =============================================================================

resource "aws_wafv2_web_acl" "nis2" {
  name        = "${var.name_prefix}-nis2-waf"
  description = "NIS2 Art.32: WAF protecting against OWASP Top 10"
  scope       = var.scope  # "REGIONAL" or "CLOUDFRONT"

  default_action { allow {} }

  # RULE 1: AWS Managed Rules — Core Rule Set (OWASP Top 10)
  rule {
    name     = "AWSManagedRulesCoreRuleSet"
    priority = 1

    override_action { none {} }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCoreRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-core-rule-set"
      sampled_requests_enabled   = true
    }
  }

  # RULE 2: AWS Managed Rules — Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action { none {} }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # RULE 3: SQL Injection protection (NIS2 Art.21 — prevent unauthorized access)
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action { none {} }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-sqli"
      sampled_requests_enabled   = true
    }
  }

  # RULE 4: Rate limiting — prevent DDoS (NIS2 Art.32)
  rule {
    name     = "RateLimitRule"
    priority = 4

    action { block {} }

    statement {
      rate_based_statement {
        limit              = var.rate_limit  # default: 2000 req/5min per IP
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  # RULE 5: Geo-restriction (optional — EU only for NIS2 Art.28)
  dynamic "rule" {
    for_each = length(var.blocked_countries) > 0 ? [1] : []
    content {
      name     = "GeoBlockRule"
      priority = 5

      action { block {} }

      statement {
        geo_match_statement {
          country_codes = var.blocked_countries
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name_prefix}-geo-block"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  tags = merge(var.tags, {
    NIS2Control = "Article-32-WAF"
    Purpose     = "WebApplicationFirewall"
  })
}

# CloudWatch alarms for WAF (NIS2 Art.23 — incident detection)
resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  alarm_name          = "${var.name_prefix}-waf-high-blocks"
  alarm_description   = "NIS2 Art.23: High rate of WAF blocked requests — possible attack"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  statistic           = "Sum"
  period              = "300"
  evaluation_periods  = "2"
  threshold           = "1000"
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    WebACL = aws_wafv2_web_acl.nis2.name
    Region = var.region
    Rule   = "ALL"
  }

  alarm_actions = var.alarm_sns_arns

  tags = merge(var.tags, { NIS2Control = "Article-23-WAFAlarm" })
}

variable "name_prefix"      { type = string }
variable "scope"            { type = string; default = "REGIONAL" }
variable "rate_limit"       { type = number; default = 2000 }
variable "blocked_countries" { type = list(string); default = [] }
variable "alarm_sns_arns"   { type = list(string); default = [] }
variable "region"           { type = string; default = "eu-central-1" }
variable "tags"             { type = map(string); default = {} }

output "waf_arn"  { value = aws_wafv2_web_acl.nis2.arn }
output "waf_id"   { value = aws_wafv2_web_acl.nis2.id }
