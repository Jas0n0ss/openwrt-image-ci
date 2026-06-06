#!/usr/bin/env bash
# Output GitHub Actions matrix JSON for device selection.
# Usage: resolve-device-matrix.sh [device|all]

set -euo pipefail

DEVICE="${1:-all}"
LIST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/configs/devices.list"

[ -f "$LIST" ] || { echo "ERROR: missing $LIST" >&2; exit 1; }

mapfile -t ALL_DEVICES < <(sed 's/#.*//' "$LIST" | xargs -n1 | grep -v '^$')

if [ "$DEVICE" = "all" ] || [ -z "$DEVICE" ]; then
  json=$(printf '"%s",' "${ALL_DEVICES[@]}" | sed 's/,$//')
  echo "{\"device\":[${json}]}"
  exit 0
fi

for d in "${ALL_DEVICES[@]}"; do
  if [ "$d" = "$DEVICE" ]; then
    echo "{\"device\":[\"${DEVICE}\"]}"
    exit 0
  fi
done

echo "ERROR: unknown device '$DEVICE'" >&2
exit 1
