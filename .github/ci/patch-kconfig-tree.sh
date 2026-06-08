#!/usr/bin/env bash
# Idempotent Kconfig cycle fixes — run inside OpenWrt/LEDE source tree before make defconfig/oldconfig.
# Usage: patch-kconfig-tree.sh [src_dir]

set -euo pipefail

SRC="${1:-.}"
cd "$SRC"

OVERLAY="${PATCH_OVERLAY:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts/overlays}"

# Custom clones under package/ — never delete when scrubbing feed duplicates.
is_protected_pkg_dir() {
  case "${1#./}" in
    package/nft-fullcone|package/luci-app-turboacc) return 0 ;;
  esac
  return 1
}

remove_pkg_by_name() {
  local name="$1"
  local mk dir
  while IFS= read -r mk; do
    [ -n "$mk" ] || continue
    dir="${mk%/Makefile}"
    is_protected_pkg_dir "$dir" && continue
    rm -rf "$dir"
    echo "==> removed package ${name}: ${dir}"
  done < <(grep -rl "PKG_NAME:=${name}\$" feeds package/feeds package 2>/dev/null || true)
  while IFS= read -r dir; do
    [ -n "$dir" ] || continue
    is_protected_pkg_dir "$dir" && continue
    rm -rf "$dir"
    echo "==> removed dir ${name}: ${dir}"
  done < <(find feeds package/feeds package -type d -name "$name" 2>/dev/null || true)
}

remove_feed_nft_fullcone_dupes() {
  local mk dir
  while IFS= read -r mk; do
    [ -n "$mk" ] || continue
    dir="${mk%/Makefile}"
    is_protected_pkg_dir "$dir" && continue
    rm -rf "$dir"
    echo "==> removed feed nft-fullcone dupe: ${dir}"
  done < <(grep -rl 'PKG_NAME:=nft-fullcone$' feeds package/feeds 2>/dev/null || true)
  while IFS= read -r dir; do
    [ -n "$dir" ] || continue
    is_protected_pkg_dir "$dir" && continue
    rm -rf "$dir"
    echo "==> removed feed nft-fullcone dir: ${dir}"
  done < <(find feeds package/feeds -type d -name 'nft-fullcone' 2>/dev/null || true)
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
remove_feed_nft_fullcone_dupes
patch_dnsmasq
apply_turboacc_overlay
[ -f package/nft-fullcone/Makefile ] \
  || { echo "ERROR: missing package/nft-fullcone (custom clone required)" >&2; exit 1; }
echo "==> patch-kconfig-tree done"
