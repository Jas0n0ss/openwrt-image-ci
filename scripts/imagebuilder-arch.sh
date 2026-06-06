#!/usr/bin/env bash
# Map device .config to OpenWrt bin/packages arch folder name.
# Usage: imagebuilder-arch.sh <device.config>

set -euo pipefail

CFG="${1:?device config}"
[ -f "$CFG" ] || { echo "ERROR: $CFG not found" >&2; exit 1; }

if grep -q '^CONFIG_TARGET_x86_64=y' "$CFG"; then
  echo x86_64
elif grep -q '^CONFIG_TARGET_qualcommax_ipq807x=y' "$CFG"; then
  echo aarch64_cortex-a53
elif grep -q '^CONFIG_TARGET_mediatek_filogic=y' "$CFG"; then
  echo aarch64_cortex-a53
elif grep -q '^CONFIG_TARGET_ramips_mt7621=y' "$CFG"; then
  # ImmortalWrt master often uses mips_24kc; collect uses detect-build-arch for cache
  echo mips_24kc
elif grep -q '^CONFIG_TARGET_rockchip_armv8=y' "$CFG"; then
  echo aarch64_generic
elif grep -q '^CONFIG_TARGET_bcm27xx_bcm2711=y' "$CFG"; then
  echo aarch64_cortex-a72
else
  echo "ERROR: unknown target in $CFG" >&2
  exit 1
fi
