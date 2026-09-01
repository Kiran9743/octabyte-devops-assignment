resource "aws_instance" "app" {
  count = var.instance_count

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private[count.index % 2].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.app.name
  associate_public_ip_address = false

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    aws_region     = var.aws_region
    ecr_repository = aws_ecr_repository.app.repository_url
    secret_arn     = aws_secretsmanager_secret.app.arn
    app_port       = var.app_port
    environment    = var.environment
    project_name   = var.project_name
  })

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-${count.index + 1}"
    Role = "application"
  }
}

resource "aws_lb_target_group_attachment" "app" {
  count = var.instance_count

  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app[count.index].id
  port             = var.app_port
}
