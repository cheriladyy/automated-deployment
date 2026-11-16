#!/usr/bin/env bash
# Destroys one self-service environment
# Usage: bash scripts/destroy-env.sh <env_name>
set -euo pipefail

ENV_NAME="${1:-}"
STATE_BUCKET="${STATE_BUCKET:-gtopaloglu-tfstate}"
STATE_PREFIX="${STATE_PREFIX:-automated-deployment/environments}"

if [[ ! "$ENV_NAME" =~ ^[a-z][a-z0-9-]{2,20}$ ]]; then
  echo "ERROR: invalid environment name: '$ENV_NAME'" >&2
  exit 1
fi

KEY="$STATE_PREFIX/$ENV_NAME/terraform.tfstate"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! aws s3api head-object --bucket "$STATE_BUCKET" --key "$KEY" >/dev/null 2>&1; then
  echo "ERROR: environment '$ENV_NAME' not found (s3://$STATE_BUCKET/$KEY does not exist)." >&2
  exit 1
fi

cd "$SCRIPT_DIR/../terraform/environments"

terraform init -reconfigure -input=false -backend-config="key=$KEY"

terraform destroy -auto-approve -input=false \
  -var "env_name=$ENV_NAME" \
  -var "template=webserver"

aws s3 rm "s3://$STATE_BUCKET/$KEY"

echo "Environment destroyed: $ENV_NAME"
