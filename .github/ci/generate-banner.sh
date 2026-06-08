#!/usr/bin/env bash
# Copy banner template into repo files/ overlay (use install-files-overlay.sh for firmware).
# Usage: generate-banner.sh <lede|immortalwrt> [files_overlay_dir]

set -euo pipefail

SOURCE="${1:?source required: lede or immortalwrt}"
FILES_ROOT_INPUT="${2:-files}"
CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/repo.sh
source "$CI_DIR/lib/repo.sh"
REPO_ROOT="$(ci_repo_root)"
OVERLAY_ROOT="$(ci_overlay_root)"

if [[ "$FILES_ROOT_INPUT" = /* ]]; then
  FILES_ROOT="$FILES_ROOT_INPUT"
else
  FILES_ROOT="$(cd "${REPO_ROOT}/${FILES_ROOT_INPUT}" 2>/dev/null && pwd)" || FILES_ROOT="${REPO_ROOT}/${FILES_ROOT_INPUT}"
fi

TEMPLATE="${OVERLAY_ROOT}/banners/${SOURCE}.banner"

case "$SOURCE" in
  lede|immortalwrt) ;;
  *)
    echo "Unknown source: $SOURCE (use lede or immortalwrt)" >&2
    exit 1
    ;;
esac

[ -f "$TEMPLATE" ] || { echo "Missing banner template: $TEMPLATE" >&2; exit 1; }

mkdir -p "${FILES_ROOT}/etc"
cp "$TEMPLATE" "${FILES_ROOT}/etc/banner"
echo "$SOURCE" > "${FILES_ROOT}/etc/jas0n0ss-build-source"

if [ "$SOURCE" = "immortalwrt" ]; then
  if ! grep -q 'BE FREE AND UNAFRAID' "${FILES_ROOT}/etc/banner"; then
    echo "ERROR: banner missing ImmortalWrt upstream art (BE FREE AND UNAFRAID)" >&2
    exit 1
  fi
  if grep -qE '^     _________$|/  LE    /|/  IM    /' "${FILES_ROOT}/etc/banner"; then
    echo "ERROR: banner is LEDE hexagon style — use overlays/banners/immortalwrt.banner" >&2
    exit 1
  fi
else
  if ! grep -qE '^     _________$|/  LE    /' "${FILES_ROOT}/etc/banner"; then
    echo "ERROR: banner missing LEDE hexagon art" >&2
    exit 1
  fi
  if grep -q 'BE FREE AND UNAFRAID' "${FILES_ROOT}/etc/banner"; then
    echo "ERROR: banner looks like ImmortalWrt template" >&2
    exit 1
  fi
fi

echo "==> Banner (${SOURCE}) -> ${FILES_ROOT}/etc/banner"
