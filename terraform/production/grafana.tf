data "aws_iam_policy_document" "grafana_assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "grafana" {
  name               = "${var.project_name}-${var.environment}-grafana-role"
  assume_role_policy = data.aws_iam_policy_document.grafana_assume_role.json

  tags = {
    Name        = "${var.project_name}-${var.environment}-grafana-role"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy" "grafana_cloudwatch" {
  name = "${var.project_name}-${var.environment}-grafana-cloudwatch-read"
  role = aws_iam_role.grafana.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeAlarms"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = [
          "tag:GetResources"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_ssm" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "grafana" {
  name = "${var.project_name}-${var.environment}-grafana-profile"
  role = aws_iam_role.grafana.name
}

resource "aws_instance" "grafana" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.large"

  subnet_id = aws_subnet.public[0].id

  vpc_security_group_ids = [
    aws_security_group.monitoring.id
  ]

  iam_instance_profile = aws_iam_instance_profile.grafana.name

  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash

    set -e

    apt-get update -y
    apt-get install -y apt-transport-https software-properties-common wget gnupg

    mkdir -p /etc/apt/keyrings

    wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg

    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
      > /etc/apt/sources.list.d/grafana.list

    apt-get update -y
    apt-get install -y grafana

    systemctl enable grafana-server
    systemctl start grafana-server
  EOF

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-grafana"
    Role        = "monitoring"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}