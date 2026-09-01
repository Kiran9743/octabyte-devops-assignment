$script = @'
#!/bin/bash
set -euo pipefail

REGION="ap-south-1"
ECR_REPOSITORY="507941514830.dkr.ecr.ap-south-1.amazonaws.com/octabyte-devops/staging/app"
SECRET_ARN="arn:aws:secretsmanager:ap-south-1:507941514830:secret:octabyte-devops/staging/application-uudcWV"
APP_PORT="8000"

echo "=== ECR LOGIN ==="
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_REPOSITORY"

echo "=== GET SECRET ==="
SECRET_JSON="$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ARN" \
  --region "$REGION" \
  --query SecretString \
  --output text)"

DB_HOST="$(echo "$SECRET_JSON" | jq -r '.DB_HOST')"
DB_PORT="$(echo "$SECRET_JSON" | jq -r '.DB_PORT')"
DB_NAME="$(echo "$SECRET_JSON" | jq -r '.DB_NAME')"
DB_USERNAME="$(echo "$SECRET_JSON" | jq -r '.DB_USERNAME')"
DB_PASSWORD="$(echo "$SECRET_JSON" | jq -r '.DB_PASSWORD')"

echo "=== SECRET CHECK ==="
echo "DB_HOST=$DB_HOST"
echo "DB_PORT=$DB_PORT"
echo "DB_NAME=$DB_NAME"
echo "DB_USERNAME=$DB_USERNAME"

IMAGE="${ECR_REPOSITORY}:latest"

echo "=== DOCKER PULL ==="
docker pull "$IMAGE"

echo "=== REMOVE OLD CONTAINER ==="
docker rm -f octabyte-app 2>/dev/null || true

echo "=== START CONTAINER ==="
docker run -d \
  --name octabyte-app \
  --restart unless-stopped \
  -p "${APP_PORT}:${APP_PORT}" \
  -e DB_HOST="$DB_HOST" \
  -e DB_PORT="$DB_PORT" \
  -e DB_NAME="$DB_NAME" \
  -e DB_USERNAME="$DB_USERNAME" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e APP_ENV="production" \
  "$IMAGE"

echo "=== CONTAINER STATUS ==="
docker ps -a --filter "name=octabyte-app"

echo "=== DEPLOYMENT COMPLETE ==="
'@

$bytes = [System.Text.Encoding]::UTF8.GetBytes($script)
$encoded = [Convert]::ToBase64String($bytes)

$CMD_FIX_SCRIPT1 = aws ssm send-command `
  --region ap-south-1 `
  --instance-ids i-01d65d743e21e6a4e `
  --document-name "AWS-RunShellScript" `
  --parameters "commands=[`"echo $encoded | base64 -d > /opt/octabyte/deploy.sh`",`"chmod +x /opt/octabyte/deploy.sh`",`"bash -n /opt/octabyte/deploy.sh`",`"ls -l /opt/octabyte/deploy.sh`"]" `
  --query "Command.CommandId" `
  --output text

$CMD_FIX_SCRIPT1