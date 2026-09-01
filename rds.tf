resource "aws_db_subnet_group" "postgres" {
  name       = "${var.project_name}-${var.environment}-postgres"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-${var.environment}-postgres"

  engine         = "postgres"
  engine_version = "17"
  instance_class = var.rds_instance_class

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  backup_retention_period = 0
  backup_window           = "18:00-19:00"
  maintenance_window      = "sun:19:00-sun:20:00"

  deletion_protection = false
  skip_final_snapshot = true

  performance_insights_enabled = true
}
