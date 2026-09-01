#!/usr/bin/env bash
set -euo pipefail

terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate

docker build -t octabyte-devops-local ./app
docker run --rm -d --name octabyte-test -p 18000:8000 octabyte-devops-local
trap 'docker rm -f octabyte-test >/dev/null 2>&1 || true' EXIT
sleep 3
curl -fsS http://localhost:18000/health
