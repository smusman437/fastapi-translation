#!/usr/bin/env bash
# Build linux/arm64 image for fastapi-translation and push to ECR.

set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

ENV="${1:-dev}"
print_app_banner
require_aws
require_terraform
terraform_init

ECR_URI="$(get_ecr_uri)"
FULL_IMAGE="${ECR_URI}:${IMAGE_TAG}"

echo "Logging in to ECR..."
aws ecr get-login-password --region "${AWS_REGION}" --profile "${AWS_PROFILE}" \
  | docker login --username AWS --password-stdin "${ECR_URI%%/*}"

echo "Building and pushing: ${FULL_IMAGE}"
echo "  Platform: linux/arm64 (matches ECS Fargate ARM64 task)"
docker buildx build \
  --platform linux/arm64 \
  -t "${FULL_IMAGE}" \
  --push \
  "${PROJECT_ROOT}"

echo ""
echo "Pushed fastapi-translation image:"
echo "  ${FULL_IMAGE}"
