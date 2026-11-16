#!/usr/bin/env bash
# Prints the active self-service environments and their remaining time as a table.
# Usage: bash scripts/list-envs.sh
set -euo pipefail

NOW_EPOCH="$(date -u +%s)"
FORMAT='%-22s %-10s %-12s %-9s %-15s %-15s %-21s %s\n'

LIST="$(aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=self-service-platform" \
            "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'Reservations[].Instances[].[Tags[?Key==`Environment`]|[0].Value, Tags[?Key==`Template`]|[0].Value, Tags[?Key==`Owner`]|[0].Value, State.Name, PublicIpAddress, PrivateIpAddress, Tags[?Key==`ExpiresAt`]|[0].Value]' \
  --output text | sort)"

# shellcheck disable=SC2059
printf "$FORMAT" NAME TEMPLATE OWNER STATE PUBLIC_IP PRIVATE_IP EXPIRES_AT REMAINING

while IFS=$'\t' read -r name template owner state public_ip private_ip expires; do
  if [ -z "$name" ]; then
    continue
  fi

  if [ -z "$expires" ] || [ "$expires" = "None" ]; then
    remaining="?"
  else
    seconds=$(( $(date -u -d "$expires" +%s) - NOW_EPOCH ))
    if [ "$seconds" -le 0 ]; then
      remaining="EXPIRED"
    else
      remaining="$((seconds / 86400))d $(((seconds % 86400) / 3600))h"
    fi
  fi

  # shellcheck disable=SC2059
  printf "$FORMAT" "$name" "$template" "$owner" "$state" "$public_ip" "$private_ip" "$expires" "$remaining"
done <<< "$LIST"
