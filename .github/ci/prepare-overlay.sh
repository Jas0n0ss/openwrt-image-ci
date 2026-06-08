#!/usr/bin/env bash
# Prepare files/ overlay into OpenWrt source tree.
# Usage: prepare-overlay.sh <lede|immortalwrt> <src_dir> [workspace]

set -euo pipefail
SOURCE="${1:?source: lede or immortalwrt}"
SRC="${2:?src dir}"
WS="${3:-${GITHUB_WORKSPACE:?}}"
CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$CI_DIR/generate-banner.sh" "$SOURCE" "$WS/files"
bash "$CI_DIR/bundle-oh-my-bash.sh" "$WS/files"
bash "$CI_DIR/install-files-overlay.sh" "$SRC" "$WS/files"
