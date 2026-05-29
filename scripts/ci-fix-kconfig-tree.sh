#!/usr/bin/env bash
# One-shot LEDE tree fix: kenzo/small purge + nftables-json dupes + Kconfig Makefile patches.
# Run after feeds cache restore and again after feeds install / custom clones.
# Usage: ci-fix-kconfig-tree.sh <src_dir>

set -euo pipefail

SRC_DIR="${1:?source directory required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SRC_DIR"

echo "==> ci-fix-kconfig-tree: start ($(pwd))"

# --- feeds.conf: never use kenzo/small (stale nftables-json / Kconfig noise) ---
if [ -f feeds.conf.default ]; then
  sed -i '\|kenzok8/openwrt-packages|d; \|kenzok8/small|d' feeds.conf.default 2>/dev/null || true
fi
if [ -f feeds.conf ]; then
  sed -i '\|kenzok8/openwrt-packages|d; \|kenzok8/small|d' feeds.conf 2>/dev/null || true
fi

rm -rf feeds/small feeds/kenzo package/feeds/small package/feeds/kenzo 2>/dev/null || true

bash "${SCRIPT_DIR}/purge-broken-feed-packages.sh" "$(pwd)"
bash "${SCRIPT_DIR}/patch-src-kconfig.sh" "$(pwd)"

# --- verify no duplicate nftables-json package definitions ---
nft_json_count=0
while IFS= read -r mk; do
  [ -n "$mk" ] || continue
  nft_json_count=$((nft_json_count + 1))
done < <(grep -Rl 'PKG_NAME:=nftables-json' . 2>/dev/null \
  | grep -vE '^\./(dl|build_dir|staging_dir)/' || true)

if [ "$nft_json_count" -gt 0 ]; then
  echo "ERROR: still found ${nft_json_count} nftables-json package Makefile(s) after purge" >&2
  grep -Rl 'PKG_NAME:=nftables-json' . 2>/dev/null | grep -vE '^\./(dl|build_dir|staging_dir)/' >&2 || true
  exit 1
fi

if [ -f package/luci-app-turboacc/Makefile ] && grep -q 'kmod-nft-fullcone' package/luci-app-turboacc/Makefile; then
  echo "ERROR: TurboACC Makefile still references kmod-nft-fullcone" >&2
  exit 1
fi

echo "==> ci-fix-kconfig-tree: OK"
