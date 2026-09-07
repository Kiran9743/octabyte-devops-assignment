# CloudWatch Metric Alarms

# CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  count = var.instance_count

  alarm_name          = "${var.project_name}-${var.environment}-ec2-cpu-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 CPU utilization exceeds 80%"
  alarm_actions       = []

  dimensions = {
    InstanceId = aws_instance.app[count.index].id
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Status Check Alarm
resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  count = var.instance_count

  alarm_name          = "${var.project_name}-${var.environment}-ec2-status-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "EC2 status check failed"
  alarm_actions       = []

  dimensions = {
    InstanceId = aws_instance.app[count.index].id
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ALB 5xx Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB returns too many 5xx errors"
  alarm_actions       = []

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
