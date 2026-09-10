resource "aws_lb" "production_app" {
  name               = "${var.project_name}-production"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb.id]
  subnets         = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-production"
    Environment = "production"
  }
}

resource "aws_lb_target_group" "production_app" {
  name     = "${var.project_name}-production"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-production"
    Environment = "production"
  }
}

resource "aws_lb_listener" "production_http" {
  load_balancer_arn = aws_lb.production_app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.production_app.arn
  }
}

resource "aws_lb_target_group_attachment" "production_app" {
  count = var.production_instance_count

  target_group_arn = aws_lb_target_group.production_app.arn
  target_id        = aws_instance.production_app[count.index].id
  port             = var.app_port
}