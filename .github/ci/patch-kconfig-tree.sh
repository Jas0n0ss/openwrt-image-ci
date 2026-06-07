#!/usr/bin/env bash
# Idempotent Kconfig cycle fixes — run inside OpenWrt/LEDE source tree before make defconfig/oldconfig.
# Usage: patch-kconfig-tree.sh [src_dir]

set -euo pipefail

SRC="${1:-.}"
cd "$SRC"

OVERLAY="${PATCH_OVERLAY:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts/overlays}"

remove_pkg_by_name() {
  local name="$1"
  while IFS= read -r mk; do
    [ -n "$mk" ] || continue
    case "$mk" in
      */package/nft-fullcone/Makefile|*/package/luci-app-turboacc/Makefile) continue ;;
    esac
    dir="$(dirname "$mk")"
    rm -rf "$dir"
    echo "==> removed package ${name}: ${dir}"
  done < <(grep -rl "PKG_NAME:=${name}\$" feeds package/feeds package 2>/dev/null || true)
  while IFS= read -r dir; do
    [ -n "$dir" ] || continue
    case "$dir" in
      ./package/nft-fullcone|./package/luci-app-turboacc) continue ;;
    esac
    rm -rf "$dir"
    echo "==> removed dir ${name}: ${dir}"
  done < <(find feeds package/feeds package -type d -name "$name" 2>/dev/null || true)
}

patch_dnsmasq() {
  local mk="package/network/services/dnsmasq/Makefile"
  [ -f "$mk" ] || return 0
  if grep -q 'dnsmasq_full_nftset:nftables-json' "$mk"; then
    sed -i 's/[[:space:]]*+PACKAGE_dnsmasq_full_nftset:nftables-json//' "$mk"
    echo "==> patched dnsmasq: dropped nftset→nftables-json"
  fi
}

apply_turboacc_overlay() {
  local mk="package/luci-app-turboacc/Makefile"
  local overlay="$OVERLAY/luci-app-turboacc/Makefile"
  [ -f "$overlay" ] || { echo "ERROR: missing $overlay" >&2; exit 1; }
  [ -d package/luci-app-turboacc ] || return 0
  cp -f "$overlay" "$mk"
  echo "==> applied luci-app-turboacc Makefile overlay (no kmod LUCI_DEPENDS)"
}

echo "==> patch-kconfig-tree in $(pwd)"
remove_pkg_by_name "nftables-json"
remove_pkg_by_name "nftables-nojson"
remove_pkg_by_name "nft-fullcone"
patch_dnsmasq
apply_turboacc_overlay
remove_pkg_by_name "nft-fullcone"
echo "==> patch-kconfig-tree done"
