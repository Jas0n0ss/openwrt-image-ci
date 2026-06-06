#!/usr/bin/env bash
# Collect custom package ipk from a full build tree for ImageBuilder reuse.
# Usage: collect-custom-ipk.sh <src_dir> <config_root> <output_dir>

set -euo pipefail

SRC="${1:?src dir}"
ROOT="${2:?config root}"
OUT="${3:?output dir}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTRACT="$SCRIPT_DIR/lib/extract-kconfig-packages.sh"

FILES=(
  "$ROOT/immortalwrt/common.config"
  "$ROOT/custom-plugins.config"
  "$ROOT/snippets/turboacc.config"
)

ARCH="$("$SCRIPT_DIR/detect-build-arch.sh" "$SRC")"
arch_dir="$SRC/bin/packages/$ARCH/packages"

[ -d "$arch_dir" ] || {
  echo "ERROR: missing $arch_dir" >&2
  exit 1
}

mapfile -t PKGS < <("$EXTRACT" "${FILES[@]}" | sort -u)

dest="$OUT/$ARCH"
mkdir -p "$dest"
found=0

for pkg in "${PKGS[@]}"; do
  shopt -s nullglob
  for ipk in "$arch_dir"/${pkg}*.ipk; do
    cp -a "$ipk" "$dest/"
    found=1
    echo "  $ARCH: $(basename "$ipk")"
  done
  shopt -u nullglob
done

# PassWall / custom feed packages often use different prefixes — copy known patterns
for pattern in luci-app-passwall passwall hysteria mosdns v2dat turboacc nft-fullcone \
  luci-theme-aurora luci-app-arpbind xray-core sing-box; do
  shopt -s nullglob
  for ipk in "$arch_dir"/${pattern}*.ipk; do
    cp -a "$ipk" "$dest/"
    found=1
    echo "  $ARCH: $(basename "$ipk") (pattern)"
  done
  shopt -u nullglob
done

if [ "$found" -eq 0 ]; then
  echo "ERROR: no custom ipk collected from $arch_dir" >&2
  exit 1
fi

echo "==> ipk saved: $dest ($(find "$dest" -name '*.ipk' | wc -l) files)"
