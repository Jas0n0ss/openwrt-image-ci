#!/usr/bin/env bash
# Build one ImmortalWrt image via official ImageBuilder (fast path).
# Usage: imagebuilder-build.sh <device> <config_root> <workspace> <ipk_cache> <output_dir>

set -euo pipefail

DEVICE="${1:?device}"
ROOT="${2:?config root}"
WORKSPACE="${3:?workspace}"
IPK_CACHE="${4:?ipk cache}"
OUT_DIR="${5:?output dir}"
IB_BASE="${IB_BASE:-https://downloads.immortalwrt.org/snapshots}"
CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/device.sh
source "$CI_DIR/lib/device.sh"

CFG="$ROOT/immortalwrt/${DEVICE}.config"
[ -f "$CFG" ] || { echo "ERROR: missing $CFG" >&2; exit 1; }

resolve_ipk_dir() {
  local predicted="$1" cache="$2" dir alt
  try_dir() { [ -d "$1" ] && [ -n "$(find "$1" -maxdepth 1 -name '*.ipk' -print -quit 2>/dev/null)" ]; }
  try_dir "$cache" && echo "$cache" && return 0
  try_dir "$cache/$predicted" && echo "$cache/$predicted" && return 0
  for alt in mips_24kc mipsel_24kc aarch64_cortex-a53 aarch64_generic aarch64_cortex-a72 x86_64; do
    try_dir "$cache/$alt" && echo "$cache/$alt" && return 0
  done
  while IFS= read -r dir; do
    [ -n "$dir" ] && try_dir "$dir" && echo "$dir" && return 0
  done < <(find "$cache" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
  echo "ERROR: no custom ipk under $cache" >&2; return 1
}

extract_packages() {
  local cfg pkg
  for cfg in \
    "$ROOT/immortalwrt/common.config" "$ROOT/custom-plugins.config" \
    "$ROOT/snippets/wireless-core.config" "$ROOT/snippets/luci-zh-cn.config" \
    "$ROOT/snippets/no-rust-passwall.config" "$ROOT/snippets/no-selinux.config" \
    "$ROOT/snippets/turboacc.config"; do
    [ -f "$cfg" ] || continue
    grep -E '^CONFIG_PACKAGE_[A-Za-z0-9][A-Za-z0-9._+-]*=y' "$cfg" \
      | sed 's/^CONFIG_PACKAGE_//;s/=y$//' | grep -vE '_INCLUDE_|_Including_' || true
  done | sort -u | tr '\n' ' ' | sed 's/ $//'
}

ARCH="$(arch_from_config "$CFG")"
IPK_SRC="$(resolve_ipk_dir "$ARCH" "$IPK_CACHE")"
echo "    arch: $ARCH"
echo "    ipk: $IPK_SRC"

PROFILE="$(grep -E '^CONFIG_TARGET_.*_DEVICE_.*=y' "$CFG" | head -1 | sed -E 's/^CONFIG_TARGET_.*_DEVICE_(.*)=y/\1/')"
if grep -q '^CONFIG_TARGET_x86_64=y' "$CFG"; then
  TARGET=x86; SUBTARGET=64; PROFILE="${PROFILE:-generic}"
else
  line="$(grep -E '^CONFIG_TARGET_[a-z0-9]+_[a-z0-9_]+=y' "$CFG" | grep -v '_DEVICE_' | head -1)"
  TARGET="$(echo "$line" | sed -E 's/^CONFIG_TARGET_([a-z0-9]+)_.*/\1/')"
  SUBTARGET="$(echo "$line" | sed -E 's/^CONFIG_TARGET_[a-z0-9]+_(.*)=y/\1/')"
fi
[ -n "$PROFILE" ] || { echo "ERROR: no profile in $CFG" >&2; exit 1; }

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
IB_URL="${IB_BASE}/targets/${TARGET}/${SUBTARGET}/immortalwrt-imagebuilder-${TARGET}-${SUBTARGET}.Linux-x86_64.tar.zst"
curl -fL --retry 3 -o "$WORKDIR/ib.tar.zst" "$IB_URL"
tar -C "$WORKDIR" -xf "$WORKDIR/ib.tar.zst"
IB_DIR="$(find "$WORKDIR" -maxdepth 1 -type d -name 'immortalwrt-imagebuilder-*' | head -1)"
[ -n "$IB_DIR" ] || { echo "ERROR: ImageBuilder extract failed" >&2; exit 1; }

mkdir -p "$IB_DIR/packages"
cp -a "$IPK_SRC"/*.ipk "$IB_DIR/packages/"

FILES_DIR="$WORKDIR/overlay"
mkdir -p "$FILES_DIR"
bash "$WORKSPACE/scripts/generate-banner.sh" immortalwrt "$WORKSPACE/files"
bash "$WORKSPACE/scripts/bundle-oh-my-bash.sh" "$WORKSPACE/files"
cp -a "$WORKSPACE/files/." "$FILES_DIR/"

PACKAGES="$(extract_packages)"
[ -n "$PACKAGES" ] || { echo "ERROR: empty package list" >&2; exit 1; }

cd "$IB_DIR"
EXTRA=""
if grep -q '^CONFIG_TARGET_ROOTFS_PARTSIZE=' "$CFG" 2>/dev/null; then
  size="$(grep '^CONFIG_TARGET_ROOTFS_PARTSIZE=' "$CFG" | sed 's/.*=//')"
  [ -n "$size" ] && EXTRA="ROOTFS_PARTSIZE=$size"
fi
# shellcheck disable=SC2086
make image PROFILE="$PROFILE" PACKAGES="$PACKAGES" FILES="$FILES_DIR" $EXTRA -j"$(nproc)"

mkdir -p "$OUT_DIR"
bash "$CI_DIR/pack-firmware.sh" "$DEVICE" immortalwrt "$CFG" "$IB_DIR/bin/targets" "$OUT_DIR"
