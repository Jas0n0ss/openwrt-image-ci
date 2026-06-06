#!/usr/bin/env bash
# Build PACKAGES= string for ImageBuilder from builder configs.
# Usage: imagebuilder-packages.sh <config_root>

set -euo pipefail

ROOT="${1:?config root}"
EXTRACT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/extract-kconfig-packages.sh"

FILES=(
  "$ROOT/immortalwrt/common.config"
  "$ROOT/custom-plugins.config"
  "$ROOT/snippets/wireless-core.config"
  "$ROOT/snippets/luci-zh-cn.config"
  "$ROOT/snippets/no-rust-passwall.config"
  "$ROOT/snippets/no-selinux.config"
  "$ROOT/snippets/turboacc.config"
)

"$EXTRACT" "${FILES[@]}" | sort -u | tr '\n' ' ' | sed 's/ $//'
