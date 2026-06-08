#!/usr/bin/env bash
# Idempotent Kconfig cycle fixes — run inside OpenWrt/LEDE source tree before make defconfig/oldconfig.
# Usage: patch-kconfig-tree.sh [src_dir]

set -euo pipefail

SRC="${1:-.}"
cd "$SRC"

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/repo.sh
source "$CI_DIR/lib/repo.sh"
OVERLAY="$(ci_overlay_root)"

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

remove_nft_fullcone_dupes() {
  local mk dir
  while IFS= read -r mk; do
    [ -n "$mk" ] || continue
    dir="${mk%/Makefile}"
    is_protected_pkg_dir "$dir" && continue
    rm -rf "$dir"
    echo "==> removed nft-fullcone dupe: ${dir}"
  done < <(grep -rl 'PKG_NAME:=nft-fullcone$' feeds package/feeds package 2>/dev/null || true)
  while IFS= read -r mk; do
    [ -n "$mk" ] || continue
    dir="${mk%/Makefile}"
    is_protected_pkg_dir "$dir" && continue
    rm -rf "$dir"
    echo "==> removed KernelPackage/nft-fullcone dupe: ${dir}"
  done < <(grep -rl 'KernelPackage/nft-fullcone' feeds package/feeds package 2>/dev/null || true)
  while IFS= read -r dir; do
    [ -n "$dir" ] || continue
    is_protected_pkg_dir "$dir" && continue
    rm -rf "$dir"
    echo "==> removed nft-fullcone dir: ${dir}"
  done < <(find feeds package/feeds package -type d -name 'nft-fullcone' 2>/dev/null || true)
}

patch_dnsmasq() {
  local mk="package/network/services/dnsmasq/Makefile"
  [ -f "$mk" ] || return 0
  if grep -q 'dnsmasq_full_nftset:nftables-json' "$mk"; then
    sed -i 's/[[:space:]]*+PACKAGE_dnsmasq_full_nftset:nftables-json//' "$mk"
    echo "==> patched dnsmasq: dropped nftset→nftables-json"
  fi
}

patch_nftables_makefile() {
  local mk="package/network/utils/nftables/Makefile"
  [ -f "$mk" ] || return 0
  if grep -q 'kmod-nft-fullcone' "$mk"; then
    sed -i 's/[[:space:]]*+kmod-nft-fullcone//' "$mk"
    echo "==> patched nftables: removed kmod-nft-fullcone from DEPENDS (breaks json/nojson cycle)"
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

apply_nft_fullcone_overlay() {
  local mk="package/nft-fullcone/Makefile"
  local overlay="$OVERLAY/nft-fullcone/Makefile"
  [ -f "$overlay" ] || { echo "ERROR: missing $overlay" >&2; exit 1; }
  [ -d package/nft-fullcone ] || return 0
  cp -f "$overlay" "$mk"
  echo "==> applied nft-fullcone Makefile overlay (no @IPV6 / PROVIDES cycle)"
}

echo "==> patch-kconfig-tree in $(pwd)"
remove_pkg_by_name "nftables-json"
remove_nft_fullcone_dupes
patch_dnsmasq
patch_nftables_makefile
apply_turboacc_overlay
apply_nft_fullcone_overlay
if [ -d package/nft-fullcone ]; then
  [ -f package/nft-fullcone/Makefile ] \
    || { echo "ERROR: missing package/nft-fullcone/Makefile" >&2; exit 1; }
else
  echo "==> note: package/nft-fullcone not present (stashed for defconfig)"
fi
echo "==> patch-kconfig-tree done"
