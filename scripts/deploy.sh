#!/usr/bin/env bash
# Full deploy: terraform plan → confirm → apply → push image → ECS rollout.

set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

ENV="${1:-dev}"
VAR_FILE="$(terraform_var_file "${ENV}")"

print_app_banner
require_aws
require_terraform
terraform_init

echo "Step 1/4: Terraform plan (${ENV})..."
(cd "${INFRA_DIR}" && terraform plan -var-file="${VAR_FILE}" -out="tfplan-${ENV}")

if ! confirm_yes "Apply this plan and deploy fastapi-translation to ECS?"; then
  echo "Aborted."
  exit 0
fi

echo "Step 2/4: Terraform apply..."
(cd "${INFRA_DIR}" && terraform apply -input=false "tfplan-${ENV}")

echo "Step 3/4: Build and push Docker image to ECR..."
"${SCRIPT_DIR}/deploy-image.sh" "${ENV}"

CLUSTER="$(get_cluster_name)"
SERVICE="$(get_service_name)"

echo "Step 4/4: Force new ECS deployment..."
aws ecs update-service \
  --profile "${AWS_PROFILE}" \
  --region "${AWS_REGION}" \
  --cluster "${CLUSTER}" \
  --service "${SERVICE}" \
  --force-new-deployment \
  --output text >/dev/null

echo "Waiting for service to become stable (models may take several minutes on first boot)..."
aws ecs wait services-stable \
  --profile "${AWS_PROFILE}" \
  --region "${AWS_REGION}" \
  --cluster "${CLUSTER}" \
  --services "${SERVICE}"

API_URL="$(get_api_url)"
echo ""
echo "Deploy complete — fastapi-translation on ECS Fargate"
echo "  Cluster:  ${CLUSTER}"
echo "  Service:  ${SERVICE}"
echo "  API URL:  ${API_URL}"
echo "  Health:   ${API_URL}${HEALTH_CHECK_PATH}"
echo "  Swagger:  ${API_URL}/apidocs"
echo "  Test:     ./scripts/test-api.sh ${API_URL}"
