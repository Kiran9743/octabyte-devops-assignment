# Architecture

## Network

- One VPC
- Two public subnets
- Two private subnets
- Internet Gateway for public traffic
- NAT Gateway for private outbound traffic

## Compute

Two private EC2 instances run the Docker application.

The ALB is public and forwards only to the application security group.

SSH is not required. AWS Systems Manager is used for operational access/deployment.

## Database

PostgreSQL RDS is deployed in private subnets and accepts TCP/5432 only from the application security group.

## CI/CD

GitHub Actions authenticates to AWS using OIDC. No permanent AWS access keys are required.

## Monitoring

The application exposes Prometheus metrics on `/metrics`.

Prometheus collects application metrics and Grafana visualizes them.

CloudWatch collects system logs and infrastructure metrics.

## Logging

Application containers write logs to stdout/stderr, which can be collected centrally. System logs are collected with the CloudWatch Agent.
