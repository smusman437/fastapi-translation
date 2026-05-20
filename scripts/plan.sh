#!/usr/bin/env bash
# Terraform plan only — review before deploy.

set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

ENV="${1:-dev}"
VAR_FILE="$(terraform_var_file "${ENV}")"

print_app_banner
require_aws
require_terraform
terraform_init

echo "Planning infrastructure for: ${PROJECT_NAME} (${ENV})"
echo "Var file: ${VAR_FILE}"
echo ""

(cd "${INFRA_DIR}" && terraform plan -var-file="${VAR_FILE}" -out="tfplan-${ENV}")

echo ""
echo "Plan saved to infra/tfplan-${ENV}"
echo "Apply with: ./scripts/deploy.sh ${ENV}"
