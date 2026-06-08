#!/usr/bin/env bash
# Copy repo files/ overlay into <src>/files/ (not source root).
# Usage: install-files-overlay.sh <build_root> [overlay_src]

set -euo pipefail

BUILD_ROOT="${1:?build root required}"
CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/repo.sh
source "$CI_DIR/lib/repo.sh"
REPO_ROOT="$(ci_repo_root)"
OVERLAY_SRC="${2:-$REPO_ROOT/files}"

if [[ "$BUILD_ROOT" != /* ]]; then
  BUILD_ROOT="$(cd "$BUILD_ROOT" && pwd)"
fi
if [[ "$OVERLAY_SRC" != /* ]]; then
  OVERLAY_SRC="$(cd "$REPO_ROOT/$OVERLAY_SRC" && pwd)"
fi

DEST="${BUILD_ROOT}/files"

[ -d "$OVERLAY_SRC" ] || { echo "ERROR: overlay source not found: $OVERLAY_SRC" >&2; exit 1; }

mkdir -p "$DEST"
cp -a "${OVERLAY_SRC}/." "$DEST/"

if [ -d "${DEST}/etc/uci-defaults" ]; then
  chmod +x "${DEST}"/etc/uci-defaults/* 2>/dev/null || true
fi

[ -f "${DEST}/etc/banner" ] || {
  echo "ERROR: overlay missing ${DEST}/etc/banner (run generate-banner.sh first)" >&2
  exit 1
}

[ -f "${DEST}/etc/jas0n0ss-build-source" ] || {
  echo "ERROR: overlay missing ${DEST}/etc/jas0n0ss-build-source (run generate-banner.sh first)" >&2
  exit 1
}

echo "==> Installed files overlay: ${OVERLAY_SRC} -> ${DEST}"
