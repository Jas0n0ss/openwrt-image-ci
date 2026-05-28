#!/usr/bin/env bash
# Copy repo files/ overlay into OpenWrt source tree (must be <src>/files/, not src root).
# Usage: install-files-overlay.sh <build_root> [overlay_src]

set -euo pipefail

BUILD_ROOT="${1:?build root required (e.g. lede, immortalwrt, src)}"
OVERLAY_SRC="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/files}"
DEST="${BUILD_ROOT}/files"

if [ ! -d "$OVERLAY_SRC" ]; then
  echo "Overlay source not found: $OVERLAY_SRC" >&2
  exit 1
fi

mkdir -p "$DEST"
# cp -a preserves times; trailing /. copies contents into files/
cp -a "${OVERLAY_SRC}/." "$DEST/"

if [ -d "${DEST}/etc/uci-defaults" ]; then
  chmod +x "${DEST}"/etc/uci-defaults/* 2>/dev/null || true
fi

echo "==> Installed files overlay: ${OVERLAY_SRC} -> ${DEST}"
