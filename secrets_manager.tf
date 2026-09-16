resource "random_password" "db" {
  length  = 24
  special = true
}

resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.project_name}/${var.environment}/application"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id

  secret_string = jsonencode({
    DB_HOST     = aws_db_instance.postgres.address
    DB_PORT     = 5432
    DB_NAME     = var.db_name
    DB_USERNAME = var.db_username
    DB_PASSWORD = random_password.db.result
  })
}
