#!/bin/bash
set -euo pipefail

REGION="ap-south-1"
ECR_REPOSITORY="507941514830.dkr.ecr.ap-south-1.amazonaws.com/octabyte-devops/staging/app"
SECRET_ARN="$(aws secretsmanager list-secrets --region "$REGION" --query "SecretList[?Name=='octabyte-devops/staging/app'].ARN | [0]" --output text)"
APP_PORT="8000"

aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_REPOSITORY"

SECRET_JSON="$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --region "$REGION" --query SecretString --output text)"

DB_HOST="$(echo "$SECRET_JSON" | jq -r '.DB_HOST')"
DB_PORT="$(echo "$SECRET_JSON" | jq -r '.DB_PORT')"
DB_NAME="$(echo "$SECRET_JSON" | jq -r '.DB_NAME')"
DB_USERNAME="$(echo "$SECRET_JSON" | jq -r '.DB_USERNAME')"
DB_PASSWORD="$(echo "$SECRET_JSON" | jq -r '.DB_PASSWORD')"

IMAGE="${ECR_REPOSITORY}:latest"

docker pull "$IMAGE"
docker rm -f octabyte-app 2>/dev/null || true

docker run -d \
  --name octabyte-app \
  --restart unless-stopped \
  -p "${APP_PORT}:${APP_PORT}" \
  -e DB_HOST="$DB_HOST" \
  -e DB_PORT="$DB_PORT" \
  -e DB_NAME="$DB_NAME" \
  -e DB_USERNAME="$DB_USERNAME" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e APP_ENV="staging" \
  "$IMAGE"