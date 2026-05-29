#!/usr/bin/env bash
# Final .config pass: explicit disables for symbols that trigger Kconfig cycles on LEDE.
# Usage: sanitize-config.sh <src_dir>

set -euo pipefail

SRC_DIR="${1:?source directory required}"
CFG="${SRC_DIR}/.config"

[ -f "$CFG" ] || {
  echo "ERROR: missing ${CFG}" >&2
  exit 1
}

# Drop any forced =y lines (defconfig may have merged duplicates)
sed -i \
  -e '/^CONFIG_PACKAGE_dnsmasq-full=y$/d' \
  -e '/^CONFIG_PACKAGE_dnsmasq_full_/d' \
  -e '/^CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_.*=y$/d' \
  -e '/^CONFIG_PACKAGE_kmod-nft-fullcone=y$/d' \
  -e '/^CONFIG_PACKAGE_kmod-nft-offload=y$/d' \
  -e '/^CONFIG_PACKAGE_kmod-tcp-bbr=y$/d' \
  -e '/^CONFIG_PACKAGE_nftables-json=y$/d' \
  -e '/^CONFIG_PACKAGE_nftables-nojson=y$/d' \
  "$CFG"

# Remove stale disable lines we are about to re-append
sed -i \
  -e '/^# CONFIG_PACKAGE_dnsmasq-full is not set$/d' \
  -e '/^# CONFIG_PACKAGE_dnsmasq_full_/d' \
  -e '/^# CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_/d' \
  -e '/^# CONFIG_PACKAGE_nftables-json is not set$/d' \
  -e '/^# CONFIG_PACKAGE_nftables-nojson is not set$/d' \
  "$CFG"

cat >>"$CFG" <<'EOF'

# --- Kconfig cycle guards (LEDE) ---
# CONFIG_PACKAGE_dnsmasq-full is not set
# CONFIG_PACKAGE_dnsmasq_full_nftset is not set
# CONFIG_PACKAGE_dnsmasq_full_dhcp is not set
# CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_OFFLOADING is not set
# CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_NFT_FULLCONE is not set
# CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_BBR_CCA is not set
# CONFIG_PACKAGE_nftables-json is not set
# CONFIG_PACKAGE_nftables-nojson is not set
EOF

echo "==> sanitize-config: applied Kconfig cycle guards"
