# ============================================================
# CloudWatch Monitoring
# ============================================================

# ------------------------------------------------------------
# SNS Topic for Monitoring Alerts
# ------------------------------------------------------------

resource "aws_sns_topic" "monitoring_alerts" {
  name = "${var.project_name}-${var.environment}-monitoring-alerts"

  tags = {
    Name        = "${var.project_name}-${var.environment}-monitoring-alerts"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# EC2 - Staging CPU Alarms
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "staging_ec2_cpu" {
  count = var.instance_count

  alarm_name = "${var.project_name}-${var.environment}-ec2-${count.index + 1}-high-cpu"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  alarm_description = "Staging EC2 instance CPU utilization is above 80%."

  dimensions = {
    InstanceId = aws_instance.app[count.index].id
  }

  alarm_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  treat_missing_data = "notBreaching"
}

# ------------------------------------------------------------
# EC2 - Production CPU Alarms
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "production_ec2_cpu" {
  count = var.production_instance_count

  alarm_name = "${var.project_name}-production-ec2-${count.index + 1}-high-cpu"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  alarm_description = "Production EC2 instance CPU utilization is above 80%."

  dimensions = {
    InstanceId = aws_instance.production_app[count.index].id
  }

  alarm_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  treat_missing_data = "notBreaching"
}

# ------------------------------------------------------------
# EC2 - Staging Status Check Alarms
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "staging_ec2_status_check" {
  count = var.instance_count

  alarm_name = "${var.project_name}-${var.environment}-ec2-${count.index + 1}-status-check"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0

  alarm_description = "Staging EC2 instance status check has failed."

  dimensions = {
    InstanceId = aws_instance.app[count.index].id
  }

  alarm_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  treat_missing_data = "breaching"
}

# ------------------------------------------------------------
# EC2 - Production Status Check Alarms
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "production_ec2_status_check" {
  count = var.production_instance_count

  alarm_name = "${var.project_name}-production-ec2-${count.index + 1}-status-check"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0

  alarm_description = "Production EC2 instance status check has failed."

  dimensions = {
    InstanceId = aws_instance.production_app[count.index].id
  }

  alarm_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  treat_missing_data = "breaching"
}

# ------------------------------------------------------------
# Staging ALB - Unhealthy Targets
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "staging_alb_unhealthy_targets" {
  alarm_name = "${var.project_name}-${var.environment}-alb-unhealthy-targets"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0

  alarm_description = "One or more staging ALB targets are unhealthy."

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  alarm_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  treat_missing_data = "notBreaching"
}

# ------------------------------------------------------------
# Production ALB - Unhealthy Targets
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "production_alb_unhealthy_targets" {
  alarm_name = "${var.project_name}-production-alb-unhealthy-targets"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0

  alarm_description = "One or more production ALB targets are unhealthy."

  dimensions = {
    LoadBalancer = aws_lb.production_app.arn_suffix
    TargetGroup  = aws_lb_target_group.production_app.arn_suffix
  }

  alarm_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  treat_missing_data = "notBreaching"
}

# ------------------------------------------------------------
# Staging ALB - HTTP 5xx
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "staging_alb_5xx" {
  alarm_name = "${var.project_name}-${var.environment}-alb-5xx"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10

  alarm_description = "Staging ALB has more than 10 HTTP 5xx errors in a 5-minute period."

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
  }

  alarm_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  treat_missing_data = "notBreaching"
}

# ------------------------------------------------------------
# Production ALB - HTTP 5xx
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "production_alb_5xx" {
  alarm_name = "${var.project_name}-production-alb-5xx"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10

  alarm_description = "Production ALB has more than 10 HTTP 5xx errors in a 5-minute period."

  dimensions = {
    LoadBalancer = aws_lb.production_app.arn_suffix
  }

  alarm_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  treat_missing_data = "notBreaching"
}

# ------------------------------------------------------------
# RDS - High CPU
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name = "${var.project_name}-${var.environment}-rds-high-cpu"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  alarm_description = "RDS CPU utilization is above 80%."

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }

  alarm_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  treat_missing_data = "notBreaching"
}

# ------------------------------------------------------------
# RDS - Low Free Storage
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name = "${var.project_name}-${var.environment}-rds-low-storage"

  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"

  # 5 GB
  threshold = 5368709120

  alarm_description = "RDS free storage is below 5 GB."

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }

  alarm_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  treat_missing_data = "notBreaching"
}

# ------------------------------------------------------------
# RDS - High Database Connections
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name = "${var.project_name}-${var.environment}-rds-high-connections"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  alarm_description = "RDS database connections are above 80."

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }

  alarm_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.monitoring_alerts.arn
  ]

  treat_missing_data = "notBreaching"
}

# ------------------------------------------------------------
# CloudWatch Dashboard
# ------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "Staging EC2 CPU"
          region = var.aws_region
          period = 300
          stat   = "Average"

          metrics = [
            for instance in aws_instance.app : [
              "AWS/EC2",
              "CPUUtilization",
              "InstanceId",
              instance.id,
              {
                label = instance.tags.Name
              }
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "Production EC2 CPU"
          region = var.aws_region
          period = 300
          stat   = "Average"

          metrics = [
            for instance in aws_instance.production_app : [
              "AWS/EC2",
              "CPUUtilization",
              "InstanceId",
              instance.id,
              {
                label = instance.tags.Name
              }
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "Staging ALB Requests"
          region = var.aws_region
          period = 300
          stat   = "Sum"

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              aws_lb.app.arn_suffix
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "Production ALB Requests"
          region = var.aws_region
          period = 300
          stat   = "Sum"

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              aws_lb.production_app.arn_suffix
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "RDS CPU"
          region = var.aws_region
          period = 300
          stat   = "Average"

          metrics = [
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier",
              aws_db_instance.postgres.id
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "RDS Free Storage"
          region = var.aws_region
          period = 300
          stat   = "Average"

          metrics = [
            [
              "AWS/RDS",
              "FreeStorageSpace",
              "DBInstanceIdentifier",
              aws_db_instance.postgres.id
            ]
          ]
        }
      }
    ]
  })
}