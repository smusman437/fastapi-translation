#!/usr/bin/env bash
# App-only redeploy: new Docker image + ECS rollout (no Terraform).

set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

ENV="${1:-dev}"

print_app_banner
require_aws
require_terraform

echo "Redeploying application code only (no infra changes)..."
"${SCRIPT_DIR}/deploy-image.sh" "${ENV}"

CLUSTER="$(get_cluster_name)"
SERVICE="$(get_service_name)"

aws ecs update-service \
  --profile "${AWS_PROFILE}" \
  --region "${AWS_REGION}" \
  --cluster "${CLUSTER}" \
  --service "${SERVICE}" \
  --force-new-deployment \
  --output text >/dev/null

echo "Waiting for stable service..."
aws ecs wait services-stable \
  --profile "${AWS_PROFILE}" \
  --region "${AWS_REGION}" \
  --cluster "${CLUSTER}" \
  --services "${SERVICE}"

API_URL="$(get_api_url)"
echo ""
echo "Redeploy complete — fastapi-translation"
echo "  API URL: ${API_URL}"
