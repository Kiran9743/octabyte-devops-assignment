resource "aws_ebs_volume" "app_data" {
  count = var.instance_count

  availability_zone = aws_instance.app[count.index].availability_zone
  size              = 20
  type              = "gp3"
  encrypted         = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-data-${count.index + 1}"
    Project     = var.project_name
    Environment = var.environment
    Role        = "application-data"
  }
}

resource "aws_volume_attachment" "app_data" {
  count = var.instance_count

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.app_data[count.index].id
  instance_id = aws_instance.app[count.index].id

  force_detach = true
}