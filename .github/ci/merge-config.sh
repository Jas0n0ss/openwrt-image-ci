#!/usr/bin/env bash
# Merge layered configs into src/.config (pre-defconfig, TurboACC stripped).
# Usage: merge-config.sh <lede|immortalwrt> <device> <src_dir> [config_root]

set -euo pipefail
SOURCE="${1:?}"
DEVICE="${2:?}"
SRC="${3:?}"
ROOT="${4:-${GITHUB_WORKSPACE:?}/configs}"

cd "$SRC"
CFG="$ROOT/${SOURCE}/${DEVICE}.config"
[ -f "$CFG" ] || { echo "ERROR: missing $CFG" >&2; exit 1; }

cat "$CFG" > .config
cat "$ROOT/${SOURCE}/common.config" >> .config
cat "$ROOT/custom-plugins.config" >> .config
for snip in \
  "$ROOT/snippets/wireless-core.config" \
  "$ROOT/snippets/luci-zh-cn.config" \
  "$ROOT/snippets/no-rust-passwall.config" \
  "$ROOT/snippets/no-selinux.config"; do
  [ -f "$snip" ] && cat "$snip" >> .config
done
echo "CONFIG_DEVEL=y" >> .config
echo "CONFIG_CCACHE=y" >> .config
sed -i \
  -e '/^CONFIG_PACKAGE_dnsmasq-full=y$/d' \
  -e '/^CONFIG_PACKAGE_dnsmasq_full_/d' \
  -e '/^CONFIG_PACKAGE_nftables-json=y$/d' \
  -e '/^CONFIG_PACKAGE_nftables-nojson=y$/d' \
  -e '/^CONFIG_PACKAGE_luci-app-turboacc/d' \
  -e '/^CONFIG_PACKAGE_kmod-nft-fullcone=y$/d' \
  -e '/^CONFIG_PACKAGE_kmod-tcp-bbr=y$/d' \
  .config
{
  echo "# CONFIG_PACKAGE_dnsmasq-full is not set"
  echo "# CONFIG_PACKAGE_nftables-json is not set"
  echo "# CONFIG_PACKAGE_nftables-nojson is not set"
} >> .config
