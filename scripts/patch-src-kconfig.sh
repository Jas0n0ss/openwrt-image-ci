#!/usr/bin/env bash
# Patch upstream Makefiles that cause Kconfig recursive dependencies on LEDE.
# Usage: patch-src-kconfig.sh <src_dir>

set -euo pipefail

SRC_DIR="${1:?source directory required}"
cd "$SRC_DIR"

patch_dnsmasq() {
  local mk="package/network/services/dnsmasq/Makefile"
  [ -f "$mk" ] || return 0
  if grep -q 'PACKAGE_dnsmasq_full_nftset:nftables-json' "$mk"; then
    sed -i 's/+PACKAGE_dnsmasq_full_nftset:nftables-json//' "$mk"
    echo "==> patch-src-kconfig: removed dnsmasq_full_nftset -> nftables-json DEPENDS"
  fi
}

patch_turboacc_makefile() {
  local mk
  for mk in package/luci-app-turboacc/Makefile feeds/*/luci-app-turboacc/Makefile; do
    [ -f "$mk" ] || continue
    # Remove conditional DEPENDS that create luci-app-turboacc <-> kmod-nft-fullcone cycle
    sed -i '/kmod-nft-fullcone/d' "$mk"
    sed -i '/kmod-nft-offload/d' "$mk"
    sed -i '/INCLUDE_NFT_FULLCONE/,/endef/{
      /default y/s/default y/default n/
    }' "$mk"
    sed -i '/INCLUDE_BBR_CCA/,/endef/{
      /default y/s/default y/default n/
    }' "$mk"
    echo "==> patch-src-kconfig: TurboACC stripped nft kmod DEPENDS in ${mk}"
  done
}

patch_dnsmasq
patch_turboacc_makefile
