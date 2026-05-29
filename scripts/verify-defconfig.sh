#!/usr/bin/env bash
# Run make defconfig and fail on Kconfig / policy errors.
# Usage: verify-defconfig.sh <src_dir>

set -euo pipefail

SRC_DIR="${1:?source directory required}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$SRC_DIR"

bash "${SCRIPT_DIR}/purge-broken-feed-packages.sh" "$(pwd)"
bash "${SCRIPT_DIR}/patch-src-kconfig.sh" "$(pwd)"

[ -f .config ] || {
  echo "ERROR: .config missing in $SRC_DIR" >&2
  exit 1
}

log="$(mktemp)"
trap 'rm -f "$log"' EXIT

set +e
make defconfig >"$log" 2>&1
rc=$?
set -e

cat "$log"

if [ "$rc" -ne 0 ]; then
  echo "ERROR: make defconfig failed (exit $rc)" >&2
  exit 1
fi

if grep -q 'recursive dependency detected' "$log"; then
  bad=0
  for sym in dnsmasq-full luci-app-turboacc_INCLUDE_NFT_FULLCONE kmod-nft-fullcone nftables-json nftables-nojson; do
    if grep -q "^CONFIG_PACKAGE_${sym}=y" .config 2>/dev/null; then
      echo "ERROR: cycle symbol enabled in .config: CONFIG_PACKAGE_${sym}=y" >&2
      bad=1
    fi
  done
  if [ "$bad" -ne 0 ]; then
    echo "ERROR: Kconfig recursive dependency — fix feeds/.config" >&2
    exit 1
  fi
  if grep -qE 'turboacc|nft-fullcone|nftables-json|nftables-nojson' "$log"; then
    echo "ERROR: Kconfig cycle metadata still present — re-run patch-src-kconfig / purge-broken-feed-packages" >&2
    exit 1
  fi
  echo "WARN: minor Kconfig recursive dependency metadata (ignored)"
fi

for bad in libselinux shadowsocks-rust naiveproxy; do
  if grep -q "^CONFIG_PACKAGE_${bad}=y" .config; then
    echo "ERROR: ${bad} must stay disabled (see configs/snippets/)" >&2
    exit 1
  fi
done

echo "==> verify-defconfig: OK"
