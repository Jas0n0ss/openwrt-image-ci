#!/usr/bin/env bash
# Emit device matrix JSON for GITHUB_OUTPUT.
# Usage: resolve-matrix.sh <all|device> [devices.list]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/device.sh
source "$SCRIPT_DIR/lib/device.sh"

PICK="${1:-all}"
LIST="${2:-${GITHUB_WORKSPACE:-.}/configs/devices.list}"
mapfile -t ALL < <(list_devices "$LIST")

if [ "$PICK" = "all" ] || [ -z "$PICK" ]; then
  json=$(printf '"%s",' "${ALL[@]}" | sed 's/,$//')
else
  for d in "${ALL[@]}"; do
    [ "$d" = "$PICK" ] && { echo "matrix={\"device\":[\"${PICK}\"]}" >> "${GITHUB_OUTPUT:?GITHUB_OUTPUT required}"; exit 0; }
  done
  echo "ERROR: unknown device '$PICK'" >&2
  exit 1
fi

echo "matrix={\"device\":[${json}]}" >> "${GITHUB_OUTPUT:?GITHUB_OUTPUT required}"
