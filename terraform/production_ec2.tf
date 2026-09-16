resource "aws_instance" "production_app" {
  count = var.production_instance_count

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.production_instance_type
  subnet_id                   = aws_subnet.private[count.index % 2].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.app.name
  associate_public_ip_address = false

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    aws_region     = var.aws_region
    ecr_repository = aws_ecr_repository.app.repository_url
    secret_arn     = aws_secretsmanager_secret.app.arn
    app_port       = var.app_port
    environment    = "production"
    project_name   = var.project_name
  })

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name        = "${var.project_name}-production-app-${count.index + 1}"
    Role        = "application"
    Environment = "production"
  }
}