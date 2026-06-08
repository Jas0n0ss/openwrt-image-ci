#!/usr/bin/env bash
# Emit ipk build matrix (arch + canonical device) from profiles/arch-canonical.list
# Usage: resolve-ipk-matrix.sh [arch-canonical.list]

set -euo pipefail
LIST="${1:-${GITHUB_WORKSPACE:-.}/profiles/arch-canonical.list}"
[ -f "$LIST" ] || { echo "ERROR: missing $LIST" >&2; exit 1; }

items=""
while read -r arch device; do
  [ -n "$arch" ] || continue
  [[ "$arch" =~ ^# ]] && continue
  [ -n "$device" ] || { echo "ERROR: missing device for arch $arch" >&2; exit 1; }
  items+="{\"arch\":\"${arch}\",\"device\":\"${device}\"},"
done < "$LIST"
items="${items%,}"
[ -n "$items" ] || { echo "ERROR: empty ipk matrix" >&2; exit 1; }
echo "matrix={\"include\":[${items}]}" >> "${GITHUB_OUTPUT:?GITHUB_OUTPUT required}"
