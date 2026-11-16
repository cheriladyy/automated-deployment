#!/usr/bin/env bash
# Usage: bash scripts/reap-expired.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Now (UTC): $NOW"

LIST="$(aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=self-service-platform" \
            "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'Reservations[].Instances[].[Tags[?Key==`Environment`]|[0].Value, Tags[?Key==`ExpiresAt`]|[0].Value]' \
  --output text | sort -u)"

reaped=0
failed=0

while IFS=$'\t' read -r name expires; do
  if [ -z "$name" ] || [ "$name" = "None" ]; then
    continue
  fi

  if [ -z "$expires" ] || [ "$expires" = "None" ]; then
    echo "SKIPPED  $name: no ExpiresAt tag"
    continue
  fi

  if [[ "$expires" < "$NOW" ]]; then
    echo "EXPIRED  $name (ExpiresAt=$expires) -> destroying"
    if bash "$SCRIPT_DIR/destroy-env.sh" "$name" < /dev/null; then
      reaped=$((reaped + 1))
    else
      echo "FAILED   $name could not be destroyed" >&2
      failed=$((failed + 1))
    fi
  else
    echo "ACTIVE   $name (ExpiresAt=$expires)"
  fi
done <<< "$LIST"

echo "Destroyed: $reaped, failed: $failed"
[ "$failed" -eq 0 ]
