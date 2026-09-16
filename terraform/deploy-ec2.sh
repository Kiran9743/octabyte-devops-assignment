#!/bin/bash
set -euo pipefail

REGION="ap-south-1"
ECR_REPOSITORY="507941514830.dkr.ecr.ap-south-1.amazonaws.com/octabyte-devops/staging/app"
SECRET_ARN="arn:aws:secretsmanager:ap-south-1:507941514830:secret:octabyte-devops/staging/application-uudcWV"

SECRET_JSON=$(/usr/local/bin/aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ARN" \
  --region "$REGION" \
  --query SecretString \
  --output text)

DB_HOST=$(echo "$SECRET_JSON" | jq -r '.DB_HOST')
DB_PORT=$(echo "$SECRET_JSON" | jq -r '.DB_PORT')
DB_NAME=$(echo "$SECRET_JSON" | jq -r '.DB_NAME')
DB_USERNAME=$(echo "$SECRET_JSON" | jq -r '.DB_USERNAME')
DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.DB_PASSWORD')

/usr/local/bin/aws ecr get-login-password --region "$REGION" |
  sudo docker login --username AWS --password-stdin 507941514830.dkr.ecr.ap-south-1.amazonaws.com

sudo docker rm -f octabyte-app 2>/dev/null || true

sudo docker run -d \
  --name octabyte-app \
  --restart unless-stopped \
  -p 8000:8000 \
  -e DB_HOST="$DB_HOST" \
  -e DB_PORT="$DB_PORT" \
  -e DB_NAME="$DB_NAME" \
  -e DB_USERNAME="$DB_USERNAME" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e APP_ENV="staging" \
  "${ECR_REPOSITORY}:latest"

sudo docker ps
