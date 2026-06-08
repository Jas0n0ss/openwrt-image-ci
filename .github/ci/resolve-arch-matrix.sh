#!/usr/bin/env bash
# Emit arch matrix JSON from profiles/arch-canonical.list
# Usage: resolve-arch-matrix.sh [arch-canonical.list]

set -euo pipefail
LIST="${1:-${GITHUB_WORKSPACE:-.}/profiles/arch-canonical.list}"
[ -f "$LIST" ] || { echo "ERROR: missing $LIST" >&2; exit 1; }

json=""
while read -r arch _device; do
  [ -n "$arch" ] || continue
  [[ "$arch" =~ ^# ]] && continue
  json+="\"${arch}\","
done < "$LIST"
json="${json%,}"
[ -n "$json" ] || { echo "ERROR: empty arch matrix" >&2; exit 1; }
echo "matrix={\"arch\":[${json}]}" >> "${GITHUB_OUTPUT:?GITHUB_OUTPUT required}"
