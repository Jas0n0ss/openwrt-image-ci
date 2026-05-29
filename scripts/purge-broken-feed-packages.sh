#!/usr/bin/env bash
# Remove duplicate nftables-json/nojson trees (kenzo/small cache) — causes self-referential Kconfig.
# Usage: purge-broken-feed-packages.sh <src_dir>

set -euo pipefail

SRC_DIR="${1:?source directory required}"
cd "$SRC_DIR"

removed=0
while IFS= read -r dir; do
  [ -n "$dir" ] || continue
  case "$dir" in
    ./dl/*|./build_dir/*|./staging_dir/*) continue ;;
  esac
  rm -rf "$dir"
  echo "==> purged: ${dir}"
  removed=$((removed + 1))
done < <(find . -type d \( -name nftables-json -o -name nftables-nojson \) 2>/dev/null \
  | grep -vE '^\./(dl|build_dir|staging_dir)/' || true)

echo "==> purge-broken-feed-packages: removed ${removed} tree(s)"
