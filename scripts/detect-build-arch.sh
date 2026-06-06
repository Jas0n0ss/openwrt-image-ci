#!/usr/bin/env bash
# Read the actual bin/packages arch folder from a full build tree.
# Usage: detect-build-arch.sh <src_dir>

set -euo pipefail

SRC="${1:?src dir}"
PKG_ROOT="$SRC/bin/packages"

[ -d "$PKG_ROOT" ] || {
  echo "ERROR: $PKG_ROOT not found" >&2
  exit 1
}

mapfile -t arches < <(find "$PKG_ROOT" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -u)

if [ "${#arches[@]}" -eq 0 ]; then
  echo "ERROR: no arch under $PKG_ROOT" >&2
  exit 1
fi

if [ "${#arches[@]}" -gt 1 ]; then
  echo "WARNING: multiple arches in build tree: ${arches[*]}" >&2
fi

echo "${arches[0]}"
