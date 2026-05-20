#!/usr/bin/env bash
# Show ECS service and ALB health for fastapi-translation.

set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

print_app_banner
require_aws

CLUSTER="$(get_cluster_name)"
SERVICE="$(get_service_name)"

if [[ -z "${CLUSTER}" || -z "${SERVICE}" ]]; then
  echo "No Terraform outputs found. Run ./scripts/deploy.sh dev first."
  exit 1
fi

echo "ECS service: ${CLUSTER} / ${SERVICE}"
aws ecs describe-services \
  --profile "${AWS_PROFILE}" \
  --region "${AWS_REGION}" \
  --cluster "${CLUSTER}" \
  --services "${SERVICE}" \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Pending:pendingCount,Deployments:deployments[*].{Status:status,Running:runningCount,Desired:desiredCount}}' \
  --output table

API_URL="$(get_api_url)"
if [[ -n "${API_URL}" ]]; then
  echo ""
  echo "ALB URL: ${API_URL}"
  echo "Health check:"
  curl -sf "${API_URL}${HEALTH_CHECK_PATH}" && echo "" || echo "  (not healthy yet)"
fi

echo ""
echo "Recent tasks:"
TASK_ARNS=$(aws ecs list-tasks \
  --profile "${AWS_PROFILE}" \
  --region "${AWS_REGION}" \
  --cluster "${CLUSTER}" \
  --service-name "${SERVICE}" \
  --query 'taskArns' --output text)

if [[ -n "${TASK_ARNS}" && "${TASK_ARNS}" != "None" ]]; then
  aws ecs describe-tasks \
    --profile "${AWS_PROFILE}" \
    --region "${AWS_REGION}" \
    --cluster "${CLUSTER}" \
    --tasks ${TASK_ARNS} \
    --query 'tasks[*].{Task:taskArn,LastStatus:lastStatus,Health:healthStatus,Container:containers[0].name,Image:containers[0].image}' \
    --output table
else
  echo "  No running tasks."
fi
