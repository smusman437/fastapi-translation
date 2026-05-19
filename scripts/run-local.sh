#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE_NAME="${IMAGE_NAME:-fastapi-translation:local}"
CONTAINER_NAME="${CONTAINER_NAME:-fastapi-translation-app}"
HOST_PORT="${HOST_PORT:-3000}"
CONTAINER_PORT="${CONTAINER_PORT:-3000}"
CACHE_DIR="${PROJECT_ROOT}/.cache/huggingface"

mkdir -p "${CACHE_DIR}"

echo "Building Docker image: ${IMAGE_NAME}"
docker build -t "${IMAGE_NAME}" "${PROJECT_ROOT}"

if docker ps -a --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
  echo "Removing existing container: ${CONTAINER_NAME}"
  docker rm -f "${CONTAINER_NAME}" >/dev/null
fi

echo "Starting container: ${CONTAINER_NAME}"
docker run -d \
  --name "${CONTAINER_NAME}" \
  -p "${HOST_PORT}:${CONTAINER_PORT}" \
  -e "PORT=${CONTAINER_PORT}" \
  -e "HF_HOME=/root/.cache/huggingface" \
  -v "${CACHE_DIR}:/root/.cache/huggingface" \
  "${IMAGE_NAME}"

echo ""
echo "Container is running."
echo "App URL: http://localhost:${HOST_PORT}"
echo "View logs: docker logs -f ${CONTAINER_NAME}"
echo "Stop app:  ${SCRIPT_DIR}/stop-local.sh"
