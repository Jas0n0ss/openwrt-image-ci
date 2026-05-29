#!/usr/bin/env bash
# One-shot LEDE tree fix: kenzo/small purge + nftables-json dupes + Makefile patches.
# Usage: ci-fix-kconfig-tree.sh <src_dir>

set -euo pipefail

SRC_DIR="${1:?source directory required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

purge_turboacc_duplicates() {
  local keep_luci="" keep_kmod=""
  [ -f package/luci-app-turboacc/Makefile ] && keep_luci="$(cd package/luci-app-turboacc && pwd)"
  [ -f package/nft-fullcone/Makefile ] && keep_kmod="$(cd package/nft-fullcone && pwd)"

  remove_dir() {
    local dir="$1" keep="$2"
    [ -n "$dir" ] || return 0
    [ -d "$dir" ] || return 0
    case "$dir" in
      package/luci-app-turboacc|./package/luci-app-turboacc|package/nft-fullcone|./package/nft-fullcone)
        return 0
        ;;
    esac
    local abs
    abs="$(cd "$dir" && pwd)"
    if [ -n "$keep" ] && [ "$abs" = "$keep" ]; then
      return 0
    fi
    rm -rf "$dir"
    echo "==> ci-fix-kconfig-tree: removed duplicate ${dir}"
  }

  purge_makefiles() {
    local pattern="$1" keep="$2"
    local mk dir
    while IFS= read -r mk; do
      [ -n "$mk" ] || continue
      case "$mk" in
        ./dl/*|./build_dir/*|./staging_dir/*|./.ci-stash-turboacc/*) continue ;;
      esac
      dir="$(dirname "$mk")"
      remove_dir "$dir" "$keep"
    done < <(grep -Rl --include='Makefile' "$pattern" feeds package/feeds package/lean 2>/dev/null || true)
  }

  purge_makefiles 'PKG_NAME:=luci-app-turboacc' "$keep_luci"
  purge_makefiles 'PKG_NAME:=nft-fullcone' "$keep_kmod"
  purge_makefiles 'PKG_NAME:=kmod-nft-fullcone' "$keep_kmod"

  while IFS= read -r mk; do
    [ -n "$mk" ] || continue
    case "$mk" in
      ./package/nft-fullcone/Makefile) continue ;;
      ./dl/*|./build_dir/*|./staging_dir/*|./.ci-stash-turboacc/*) continue ;;
    esac
    remove_dir "$(dirname "$mk")" "$keep_kmod"
  done < <(grep -Rl 'KernelPackage/nft-fullcone' feeds package/feeds package/lean 2>/dev/null || true)

  rm -rf \
    feeds/luci/applications/luci-app-turboacc \
    feeds/luci/applications/luci-app-turboacc-chenmozhijin 2>/dev/null || true

  local base dir
  for base in feeds package/feeds package/lean; do
    [ -d "$base" ] || continue
    while IFS= read -r dir; do
      remove_dir "$dir" "$keep_luci"
    done < <(find "$base" -type d -name luci-app-turboacc 2>/dev/null || true)
    while IFS= read -r dir; do
      remove_dir "$dir" "$keep_kmod"
    done < <(find "$base" -type d \( -name nft-fullcone -o -name kmod-nft-fullcone \) 2>/dev/null || true)
  done
}

cd "$SRC_DIR"

echo "==> ci-fix-kconfig-tree: start ($(pwd))"

if [ -f feeds.conf.default ]; then
  sed -i '\|kenzok8/openwrt-packages|d; \|kenzok8/small|d' feeds.conf.default 2>/dev/null || true
fi
if [ -f feeds.conf ]; then
  sed -i '\|kenzok8/openwrt-packages|d; \|kenzok8/small|d' feeds.conf 2>/dev/null || true
fi

rm -rf feeds/small feeds/kenzo package/feeds/small package/feeds/kenzo 2>/dev/null || true

bash "${SCRIPT_DIR}/purge-broken-feed-packages.sh" "$(pwd)"
bash "${SCRIPT_DIR}/patch-src-kconfig.sh" "$(pwd)"
purge_turboacc_duplicates

# nftables-json dupes must be gone; kmod-nft-fullcone may exist via package/nft-fullcone (TurboACC)
nft_json_count=0
while IFS= read -r mk; do
  [ -n "$mk" ] || continue
  nft_json_count=$((nft_json_count + 1))
done < <(grep -Rl 'PKG_NAME:=nftables-json' . 2>/dev/null \
  | grep -vE '^\./(dl|build_dir|staging_dir)/' || true)

if [ "$nft_json_count" -gt 0 ]; then
  echo "ERROR: still found ${nft_json_count} nftables-json package(s) after purge" >&2
  grep -Rl 'PKG_NAME:=nftables-json' . 2>/dev/null | grep -vE '^\./(dl|build_dir|staging_dir)/' >&2 || true
  exit 1
fi

if [ -f package/luci-app-turboacc/Makefile ] && [ ! -f package/nft-fullcone/Makefile ]; then
  echo "ERROR: luci-app-turboacc without package/nft-fullcone (incomplete TurboACC)" >&2
  exit 1
fi

# At most one luci-app-turboacc / nft-fullcone package tree (duplicate = Kconfig self-cycle)
luci_dupes=0
while IFS= read -r mk; do
  [ -n "$mk" ] || continue
  luci_dupes=$((luci_dupes + 1))
done < <(grep -Rl --include=Makefile 'PKG_NAME:=luci-app-turboacc' package package/feeds 2>/dev/null || true)

if [ "$luci_dupes" -gt 1 ]; then
  echo "ERROR: ${luci_dupes} luci-app-turboacc packages still present (expected 0–1)" >&2
  grep -Rl --include=Makefile 'PKG_NAME:=luci-app-turboacc' package package/feeds 2>/dev/null >&2 || true
  exit 1
fi

kmod_dupes=0
while IFS= read -r mk; do
  [ -n "$mk" ] || continue
  kmod_dupes=$((kmod_dupes + 1))
done < <(grep -Rl 'KernelPackage/nft-fullcone' package package/feeds 2>/dev/null || true)

if [ "$kmod_dupes" -gt 1 ]; then
  echo "ERROR: ${kmod_dupes} KernelPackage/nft-fullcone definitions (expected 0–1)" >&2
  grep -Rl 'KernelPackage/nft-fullcone' package package/feeds 2>/dev/null >&2 || true
  exit 1
fi

echo "==> ci-fix-kconfig-tree: OK"
