#!/usr/bin/env bash
set -euo pipefail

#######################################
# Helpers
#######################################
log() {
  echo "[INFO] $1"
}

error() {
  echo "[ERROR] $1" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || error "Missing dependency: $1"
}

get_ssm() {
  local param="$1"
  set +e
  local value
  value=$(
    aws ssm get-parameter \
      --name "$param" \
      --with-decryption \
      --query "Parameter.Value" \
      --output text 2>&1
  )
  local exit_code=$?
  set -e

  if [ "$exit_code" -ne 0 ]; then
    error "Failed to fetch '$param' from SSM:
$value"
  fi

  echo "$value"
}

usage() {
  cat <<'EOF'
Usage: ./bin/generate_env.sh [OPTIONS]

Options:
  --stage STAGE  Specify the stage to target (default: dev)
  --help         Show this help message
EOF
}

#######################################
# Stage resolution
#######################################
STAGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stage)
      STAGE="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

STAGE="${STAGE:-${STAGE:-dev}}"

#######################################
# Derived configuration
#######################################
AWS_REGION="${AWS_REGION:-ap-southeast-1}"
SSM_PREFIX="/koins/${STAGE}"

RAILS_ENV="$STAGE"
[ "$STAGE" = "prod" ] && RAILS_ENV="production"

RACK_ENV="${RAILS_ENV}"

ENV_FILE=".env.${RAILS_ENV}"

#######################################
# Pre-flight checks
#######################################
require_cmd aws
require_cmd sed

log "Stage           : $STAGE"
log "AWS Region      : $AWS_REGION"
log "SSM Prefix      : $SSM_PREFIX"
log "Env file        : $ENV_FILE"

#######################################
# Safety guard
#######################################
if [[ "$STAGE" == "prod" && "${CI:-false}" == "true" ]]; then
  error "Refusing to run against prod in CI"
fi

#######################################
# Fetch secrets from SSM
#######################################
log "Fetching parameters from SSM"

DATABASE_USERNAME=$(get_ssm "$SSM_PREFIX/db/main/username")
DATABASE_PASSWORD=$(get_ssm "$SSM_PREFIX/db/main/password")
DATABASE_HOST=$(get_ssm "$SSM_PREFIX/db/main/host")
DATABASE_NAME=$(get_ssm "$SSM_PREFIX/db/main/name")

SECRET_KEY_BASE=$(get_ssm "$SSM_PREFIX/rails/secret_key_base")

#######################################
# Write environment file
#######################################
log "Generating $ENV_FILE"

cat > "$ENV_FILE" <<EOF
#######################################
# Rails Runtime
#######################################
RAILS_ENV=$RAILS_ENV
PORT=3000

RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true

SECRET_KEY_BASE=$SECRET_KEY_BASE

BUNDLER_VERSION=2.6.2

#######################################
# Main Database
#######################################
DATABASE_USERNAME=$DATABASE_USERNAME
DATABASE_PASSWORD=$DATABASE_PASSWORD
DATABASE_HOST=$DATABASE_HOST
DATABASE_NAME=$DATABASE_NAME

#######################################
# Application Specific
#######################################
BASE_URL="$BASE_URL"
EMAIL_SENDER=$EMAIL_SENDER

#######################################
# AWS / LocalStack
#######################################
AWS_ACCESS_KEY_ID=\${AWS_ACCESS_KEY_ID:-test}
AWS_SECRET_ACCESS_KEY_ID=\${AWS_SECRET_ACCESS_KEY_ID:-test}
AWS_REGION=$AWS_REGION
AWS_BUCKET=$AWS_BUCKET
AWS_SQS_REPORT_QUEUE=$AWS_SQS_REPORT_QUEUE
EOF

#######################################
# Validation
#######################################
log "Validating generated environment file"

REQUIRED_VARS=(
  RAILS_ENV
  PORT
  SECRET_KEY_BASE
  BUNDLER_VERSION
  DATABASE_USERNAME
  DATABASE_PASSWORD
  DATABASE_HOST
  DATABASE_NAME
  DATABASE_PORT
)

for var in "${REQUIRED_VARS[@]}"; do
  grep -q "^$var=" "$ENV_FILE" || error "Missing $var in $ENV_FILE"
done

log "Environment validation passed"

#######################################
# Load env
#######################################
log "Loading environment variables"
set -a
source "$ENV_FILE"
set +a

#######################################
# Done
#######################################
log "Generated .env file for stage '$STAGE'"
