#!/usr/bin/env bash
# Smoke-test fastapi-translation API (health + translate + Swagger).

set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

BASE_URL="${1:-http://localhost:${CONTAINER_PORT}}"
BASE_URL="${BASE_URL%/}"

print_app_banner
echo "Testing: ${BASE_URL}"
echo ""

echo "1. GET ${HEALTH_CHECK_PATH}"
curl -sf "${BASE_URL}${HEALTH_CHECK_PATH}" | python3 -m json.tool
echo ""

echo "2. POST /translate/"
curl -sf -X POST "${BASE_URL}/translate/" \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello, how are you?"}' | python3 -m json.tool
echo ""

echo "3. GET /apidocs (Swagger UI — expect HTTP 200)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/apidocs")
echo "   Status: ${HTTP_CODE}"
[[ "${HTTP_CODE}" == "200" ]] || { echo "Swagger check failed"; exit 1; }

echo ""
echo "All checks passed for fastapi-translation."
