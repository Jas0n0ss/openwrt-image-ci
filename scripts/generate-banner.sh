#!/usr/bin/env bash
# Copy banner template into repo files/ overlay (use install-files-overlay.sh for firmware).
# Usage: generate-banner.sh <lede|immortalwrt> [files_overlay_dir]

set -euo pipefail

SOURCE="${1:?source required: lede or immortalwrt}"
FILES_ROOT_INPUT="${2:-files}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Resolve to absolute path (avoid writing to wrong ./files when cwd differs)
if [[ "$FILES_ROOT_INPUT" = /* ]]; then
  FILES_ROOT="$FILES_ROOT_INPUT"
else
  FILES_ROOT="$(cd "${REPO_ROOT}/${FILES_ROOT_INPUT}" 2>/dev/null && pwd)" || FILES_ROOT="${REPO_ROOT}/${FILES_ROOT_INPUT}"
fi

TEMPLATE="${SCRIPT_DIR}/banners/${SOURCE}.banner"

case "$SOURCE" in
  lede|immortalwrt) ;;
  *)
    echo "Unknown source: $SOURCE (use lede or immortalwrt)" >&2
    exit 1
    ;;
esac

if [ ! -f "$TEMPLATE" ]; then
  echo "Missing banner template: $TEMPLATE" >&2
  exit 1
fi

mkdir -p "${FILES_ROOT}/etc"
cp "$TEMPLATE" "${FILES_ROOT}/etc/banner"
echo "$SOURCE" > "${FILES_ROOT}/etc/jas0n0ss-build-source"

# Verify the correct template was applied (ImmortalWrt ≠ LEDE hexagon)
if [ "$SOURCE" = "immortalwrt" ]; then
  if ! grep -q 'BE FREE AND UNAFRAID' "${FILES_ROOT}/etc/banner"; then
    echo "ERROR: banner missing ImmortalWrt upstream art (BE FREE AND UNAFRAID)" >&2
    exit 1
  fi
  if grep -qE '^     _________$|/  LE    /|/  IM    /' "${FILES_ROOT}/etc/banner"; then
    echo "ERROR: banner is LEDE hexagon style — use scripts/banners/immortalwrt.banner" >&2
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
echo "    Next: install-files-overlay.sh <lede|immortalwrt|src> ${FILES_ROOT}"
