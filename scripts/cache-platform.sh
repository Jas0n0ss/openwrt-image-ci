#!/usr/bin/env bash
# Print OpenWrt target platform slug for shared CI cache keys.
# Usage: cache-platform.sh <device.config>

set -euo pipefail

CONFIG_FILE="${1:?device config path}"

if line=$(grep -E '^CONFIG_TARGET_.*_DEVICE_.*=y' "$CONFIG_FILE" 2>/dev/null | head -1); then
  platform=$(echo "$line" | sed -E 's/^CONFIG_TARGET_(.*)_DEVICE_.*/\1/' | tr '_' '-')
elif grep -q '^CONFIG_TARGET_x86_64=y' "$CONFIG_FILE" 2>/dev/null; then
  platform="x86-64"
else
  targets=()
  while IFS= read -r line; do
    targets+=("$line")
  done < <(
    grep -E '^CONFIG_TARGET_[A-Za-z0-9_]+=y' "$CONFIG_FILE" \
      | grep -v '_DEVICE_' | grep -v 'ROOTFS' | grep -v 'KERNEL' | grep -v 'IMAGES' \
      | sed -E 's/^CONFIG_TARGET_(.*)=y/\1/' | tr '_' '-' || true
  )
  if [ "${#targets[@]}" -gt 0 ]; then
    platform=$(IFS=-; echo "${targets[*]}")
  else
    platform="unknown"
  fi
fi

echo "$platform" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g'
