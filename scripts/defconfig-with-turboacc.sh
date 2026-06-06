#!/usr/bin/env bash
# Base make defconfig (TurboACC stashed), then enable TurboACC via oldconfig.
# Usage: defconfig-with-turboacc.sh <config_root> <src_dir>

set -euo pipefail

ROOT="${1:?config root}"
SRC="${2:?src dir}"
cd "$SRC"

fail_on_kconfig_cycles() {
  local log="$1"
  local phase="$2"

  grep -q 'recursive dependency detected' "$log" || return 0

  echo "=== Kconfig recursive dependency during ${phase} ===" >&2
  grep -E 'recursive dependency|symbol PACKAGE_' "$log" >&2 || true

  local sym fail=0
  for sym in \
    dnsmasq-full luci-app-turboacc kmod-nft-fullcone \
    nftables-json nftables-nojson luci-ssl luci-app-unblockneteasemusic; do
    if grep -q "^CONFIG_PACKAGE_${sym}=y" .config 2>/dev/null; then
      echo "ERROR: cycle-prone package enabled in .config: ${sym}" >&2
      fail=1
    fi
  done

  if [ "$fail" -ne 0 ]; then
    exit 1
  fi

  echo "WARN: ${phase} reported recursive dependency metadata; cycle packages stay disabled" >&2
}

STASH=".ci-stash-turboacc"
mkdir -p "$STASH"
for d in luci-app-turboacc nft-fullcone; do
  [ -d "package/$d" ] && mv "package/$d" "$STASH/$d"
done

make defconfig > defconfig.log 2>&1 || {
  echo "make defconfig failed:" >&2
  cat defconfig.log >&2
  exit 1
}
fail_on_kconfig_cycles defconfig.log defconfig

for d in luci-app-turboacc nft-fullcone; do
  [ -d "$STASH/$d" ] && mv "$STASH/$d" "package/$d"
done

cat "$ROOT/snippets/turboacc.config" >> .config
make oldconfig > oldconfig.log 2>&1 || {
  echo "make oldconfig failed:" >&2
  cat oldconfig.log >&2
  exit 1
}

if grep -q 'recursive dependency detected' oldconfig.log; then
  echo "=== Kconfig recursive dependency during oldconfig (TurboACC) ===" >&2
  grep -E 'recursive dependency|symbol PACKAGE_' oldconfig.log >&2 || true
  exit 1
fi

echo "==> defconfig + TurboACC: OK"
