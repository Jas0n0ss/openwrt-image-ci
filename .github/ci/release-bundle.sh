#!/usr/bin/env bash
# Bundle downloaded firmware artifacts and optionally verify all devices.
# Usage: release-bundle.sh <source> <artifact_glob_prefix> <device_input> [devices.list]

set -euo pipefail
SOURCE="${1:?}"          # lede | immortalwrt
PREFIX="${2:?}"          # fw-lede | fw-immortalwrt | fw-firmware
INPUT="${3:-all}"
LIST="${4:-${GITHUB_WORKSPACE:-.}/configs/devices.list}"

mkdir -p release
shopt -s nullglob
files=(artifacts/**/Jas0n0ss-*)
[ "${#files[@]}" -gt 0 ] || { echo "ERROR: no firmware files downloaded" >&2; exit 1; }
cp -t release/ "${files[@]}"
echo "Bundled ${#files[@]} firmware file(s):"
ls -la release/

if [ "$INPUT" = "all" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  # shellcheck source=lib/device.sh
  source "$SCRIPT_DIR/lib/device.sh"
  while IFS= read -r dev; do
    [ -n "$dev" ] || continue
    ls release/Jas0n0ss-"${SOURCE}"-"${dev}"-* >/dev/null 2>&1 \
      || { echo "ERROR: missing firmware for device: $dev" >&2; exit 1; }
  done < <(list_devices "$LIST")
fi
