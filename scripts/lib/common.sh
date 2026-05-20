#!/usr/bin/env bash
# Shared helpers for fastapi-translation deploy scripts.
# Every resource name matches the app so you can trace image → container → ECS service.

set -euo pipefail

export AWS_PROFILE="${AWS_PROFILE:-terraform-user}"
export AWS_PAGER=""

# --- App identity (keep in sync with infra/terraform.tfvars) ---
export PROJECT_NAME="${PROJECT_NAME:-fastapi-translation}"
export CONTAINER_PORT="${CONTAINER_PORT:-3000}"
export HEALTH_CHECK_PATH="${HEALTH_CHECK_PATH:-/health}"
export AWS_REGION="${AWS_REGION:-us-east-1}"
export IMAGE_TAG="${IMAGE_TAG:-latest}"

# Local Docker names (scripts/local.sh)
export LOCAL_IMAGE="${LOCAL_IMAGE:-fastapi-translation:local}"
export LOCAL_CONTAINER="${LOCAL_CONTAINER:-fastapi-translation-app}"

_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPTS_DIR="$(cd "${_lib_dir}/.." && pwd)"
export SCRIPT_DIR="${SCRIPTS_DIR}"
export PROJECT_ROOT="$(cd "${SCRIPTS_DIR}/.." && pwd)"
export INFRA_DIR="${PROJECT_ROOT}/infra"

print_app_banner() {
  cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  App:       fastapi-translation
  Purpose:   English → Turkish translator (FastAPI + Hugging Face)
  Port:      ${CONTAINER_PORT}
  Health:    ${HEALTH_CHECK_PATH}
  Profile:   ${AWS_PROFILE}
  Region:    ${AWS_REGION}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
}

require_aws() {
  if ! aws sts get-caller-identity --profile "${AWS_PROFILE}" >/dev/null 2>&1; then
    echo "ERROR: AWS profile '${AWS_PROFILE}' is not configured."
    echo "Run: aws configure --profile ${AWS_PROFILE}"
    exit 1
  fi
}

require_terraform() {
  if ! command -v terraform >/dev/null 2>&1; then
    echo "ERROR: terraform not found. Install darwin_arm64 build on Apple Silicon."
    exit 1
  fi
}

terraform_var_file() {
  local env="${1:-dev}"
  if [[ "${env}" == "prod" ]]; then
    echo "${INFRA_DIR}/prod.tfvars"
  else
    echo "${INFRA_DIR}/terraform.tfvars"
  fi
}

terraform_init() {
  (cd "${INFRA_DIR}" && terraform init -input=false)
}

terraform_output_raw() {
  local name="$1"
  (cd "${INFRA_DIR}" && terraform output -raw "${name}" 2>/dev/null) || true
}

get_ecr_uri() {
  local uri
  uri="$(terraform_output_raw ecr_uri)"
  if [[ -z "${uri}" ]]; then
    echo "ERROR: ecr_uri not in Terraform state. Run ./scripts/deploy.sh ${1:-dev} first." >&2
    exit 1
  fi
  echo "${uri}"
}

get_api_url() {
  terraform_output_raw api_url
}

get_cluster_name() {
  terraform_output_raw ecs_cluster_name
}

get_service_name() {
  terraform_output_raw ecs_service_name
}

confirm_yes() {
  local prompt="${1:-Continue?}"
  read -r -p "${prompt} [yes/N]: " answer
  [[ "${answer}" == "yes" ]]
}
