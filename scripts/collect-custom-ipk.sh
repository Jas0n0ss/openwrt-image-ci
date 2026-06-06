#!/usr/bin/env bash
# Collect custom package ipk from a full build tree for ImageBuilder reuse.
# Usage: collect-custom-ipk.sh <src_dir> <config_root> <output_dir>

set -euo pipefail

SRC="${1:?src dir}"
ROOT="${2:?config root}"
OUT="${3:?output dir}"
EXTRACT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/extract-kconfig-packages.sh"

FILES=(
  "$ROOT/immortalwrt/common.config"
  "$ROOT/custom-plugins.config"
  "$ROOT/snippets/turboacc.config"
)

mapfile -t PKGS < <("$EXTRACT" "${FILES[@]}" | sort -u)

mkdir -p "$OUT"
found=0

for arch_dir in "$SRC"/bin/packages/*/packages; do
  [ -d "$arch_dir" ] || continue
  arch="$(basename "$(dirname "$arch_dir")")"
  dest="$OUT/$arch"
  mkdir -p "$dest"

  for pkg in "${PKGS[@]}"; do
    for ipk in "$arch_dir"/${pkg}[_-]*.ipk "$arch_dir"/${pkg}.ipk; do
      [ -f "$ipk" ] || continue
      cp -a "$ipk" "$dest/"
      found=1
      echo "  $arch: $(basename "$ipk")"
    done
  done
done

if [ "$found" -eq 0 ]; then
  echo "WARNING: no custom ipk collected (run full build first)" >&2
fi

echo "==> ipk saved under $OUT"
