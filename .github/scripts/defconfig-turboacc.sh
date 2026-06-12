#!/usr/bin/env bash
# patch-kconfig-tree + defconfig + cycle-scrub + TurboACC oldconfig.
# Usage: defconfig-turboacc.sh <src_dir> [workspace]

set -euo pipefail
SRC="${1:?}"
WS="${2:-${GITHUB_WORKSPACE:?}}"

cd "$SRC"
PATCH="$WS/.github/scripts/patch-kconfig-tree.sh"
export PATCH_OVERLAY="$WS/overlays"
STASH="$WS/.turboacc-stash"

stash_turboacc() {
  rm -rf "$STASH"
  mkdir -p "$STASH"
  local pkg
  for pkg in luci-app-turboacc nft-fullcone; do
    if [ -d "package/$pkg" ]; then
      mv "package/$pkg" "$STASH/"
      echo "==> stashed package/$pkg for base defconfig"
    fi
  done
}

restore_turboacc() {
  local pkg
  for pkg in luci-app-turboacc nft-fullcone; do
    if [ -d "$STASH/$pkg" ]; then
      mv "$STASH/$pkg" "package/"
      echo "==> restored package/$pkg"
    fi
  done
  rm -rf "$STASH"
  [ -f package/nft-fullcone/Makefile ] \
    || { echo "ERROR: missing package/nft-fullcone after restore" >&2; exit 1; }
}

stash_turboacc
bash "$PATCH" .
make defconfig > defconfig.log 2>&1 || { echo "make defconfig failed:"; cat defconfig.log; exit 1; }
if grep -q 'recursive dependency detected' defconfig.log; then
  echo "=== Kconfig recursive dependency (defconfig) ==="
  grep -E 'recursive dependency|symbol PACKAGE_' defconfig.log || true
  exit 1
fi

# Scrub Kconfig cycle-prone symbols from .config
sed -i \
  -e '/^CONFIG_PACKAGE_dnsmasq-full=y$/d' \
  -e '/^CONFIG_PACKAGE_dnsmasq_full_/d' \
  .config
{
  echo "# CONFIG_PACKAGE_dnsmasq-full is not set"
  echo "# CONFIG_PACKAGE_dnsmasq_full_nftset is not set"
} >> .config

restore_turboacc
bash "$PATCH" .
rm -rf tmp/.config-package.in tmp/.config-target.in tmp/.config-feeds.in 2>/dev/null || true
cat "$WS/configs/snippets/turboacc.config" >> .config
make oldconfig > oldconfig.log 2>&1 || { echo "make oldconfig failed:"; cat oldconfig.log; exit 1; }
if grep -q 'recursive dependency detected' oldconfig.log; then
  echo "=== Kconfig recursive dependency (oldconfig) ==="
  grep -E 'recursive dependency|symbol PACKAGE_' oldconfig.log || true
  exit 1
fi
