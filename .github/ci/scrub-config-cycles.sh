#!/usr/bin/env bash
# Strip Kconfig cycle-prone symbols from .config (after make defconfig).
# Usage: scrub-config-cycles.sh [path/to/.config]

set -euo pipefail

CFG="${1:-.config}"
[ -f "$CFG" ] || { echo "ERROR: missing $CFG" >&2; exit 1; }

sed -i \
  -e '/^CONFIG_PACKAGE_dnsmasq-full=y$/d' \
  -e '/^CONFIG_PACKAGE_dnsmasq_full_/d' \
  "$CFG"

{
  echo "# CONFIG_PACKAGE_dnsmasq-full is not set"
  echo "# CONFIG_PACKAGE_dnsmasq_full_nftset is not set"
} >> "$CFG"
