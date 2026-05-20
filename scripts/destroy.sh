#!/usr/bin/env bash
# Tear down AWS resources for fastapi-translation (ECR force-delete + terraform destroy).

set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

ENV="${1:-dev}"
VAR_FILE="$(terraform_var_file "${ENV}")"

print_app_banner
require_aws
require_terraform
terraform_init

if ! confirm_yes "Destroy ALL AWS resources for fastapi-translation (${ENV})?"; then
  echo "Aborted."
  exit 0
fi

echo "Force-deleting ECR repository: ${PROJECT_NAME}..."
aws ecr delete-repository \
  --profile "${AWS_PROFILE}" \
  --region "${AWS_REGION}" \
  --repository-name "${PROJECT_NAME}" \
  --force 2>/dev/null || echo "  (ECR repo already gone or not created)"

echo "Removing ECR from Terraform state (if present)..."
(cd "${INFRA_DIR}" && terraform state rm aws_ecr_repository.app 2>/dev/null) || true

echo "Running terraform destroy..."
(cd "${INFRA_DIR}" && terraform destroy -var-file="${VAR_FILE}" -auto-approve)

echo ""
echo "Destroyed fastapi-translation infrastructure (${ENV})."
