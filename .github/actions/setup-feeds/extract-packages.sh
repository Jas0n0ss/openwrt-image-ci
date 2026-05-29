#!/usr/bin/env bash
# Extract package names from Kconfig .config files
set -euo pipefail

[ $# -eq 1 ] || { echo "Usage: $0 <config-file>" >&2; exit 1; }
[ -f "$1" ] || { echo "ERROR: $1 not found" >&2; exit 1; }

# Extract package names from CONFIG_PACKAGE_*=y lines
grep -oE 'CONFIG_PACKAGE_[a-zA-Z0-9_-]+=y' "$1" 2>/dev/null | \
  sed 's/CONFIG_PACKAGE_//' | \
  sed 's/=y$//' | \
  sort -u || true
