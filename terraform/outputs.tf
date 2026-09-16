output "vpc_id" {
  value = aws_vpc.main.id
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "rds_endpoint" {
  value     = aws_db_instance.postgres.address
  sensitive = true
}

output "secret_arn" {
  value     = aws_secretsmanager_secret.app.arn
  sensitive = true
}

output "instance_ids" {
  value = aws_instance.app[*].id
}

output "instance_private_ips" {
  value = aws_instance.app[*].private_ip
}
output "production_alb_dns_name" {
  value = aws_lb.production_app.dns_name
}

output "production_instance_ids" {
  value = aws_instance.production_app[*].id
}

output "production_instance_private_ips" {
  value = aws_instance.production_app[*].private_ip
}
output "app_ebs_volume_ids" {
  description = "EBS volume IDs attached to application instances"
  value       = aws_ebs_volume.app_data[*].id
}

output "grafana_instance_id" {
  description = "Grafana EC2 instance ID"
  value       = aws_instance.grafana.id
}

output "grafana_public_ip" {
  description = "Grafana public IP address"
  value       = aws_instance.grafana.public_ip
}

output "grafana_public_dns" {
  description = "Grafana public DNS name"
  value       = aws_instance.grafana.public_dns
}

output "grafana_url" {
  description = "Grafana web UI URL"
  value       = "http://${aws_instance.grafana.public_ip}:3000"
}
