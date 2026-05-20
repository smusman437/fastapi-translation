#!/usr/bin/env bash
# Build and run fastapi-translation locally in Docker (same app as ECS, local image tag).

set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

print_app_banner

CACHE_DIR="${PROJECT_ROOT}/.cache/huggingface"
mkdir -p "${CACHE_DIR}"

echo "Building image:  ${LOCAL_IMAGE}"
echo "  (labels identify app: fastapi-translation)"
docker build -t "${LOCAL_IMAGE}" "${PROJECT_ROOT}"

if docker ps -a --format '{{.Names}}' | grep -qx "${LOCAL_CONTAINER}"; then
  echo "Removing old container: ${LOCAL_CONTAINER}"
  docker rm -f "${LOCAL_CONTAINER}" >/dev/null
fi

echo "Starting container: ${LOCAL_CONTAINER}"
docker run -d \
  --name "${LOCAL_CONTAINER}" \
  -p "${CONTAINER_PORT}:${CONTAINER_PORT}" \
  -e "PORT=${CONTAINER_PORT}" \
  -e "APP_NAME=${PROJECT_NAME}" \
  -e "HF_HOME=/root/.cache/huggingface" \
  -v "${CACHE_DIR}:/root/.cache/huggingface" \
  "${LOCAL_IMAGE}"

echo ""
echo "Local fastapi-translation is running."
echo "  UI:      http://localhost:${CONTAINER_PORT}/"
echo "  Health:  http://localhost:${CONTAINER_PORT}${HEALTH_CHECK_PATH}"
echo "  Swagger: http://localhost:${CONTAINER_PORT}/apidocs"
echo "  Logs:    docker logs -f ${LOCAL_CONTAINER}"
echo "  Stop:    ./scripts/stop-local.sh"
