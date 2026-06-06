#!/usr/bin/env bash
# Build one ImmortalWrt image via official ImageBuilder (fast path).
# Usage: imagebuilder-build.sh <device> <config_root> <workspace> <ipk_cache> <output_dir>
#
# Requires custom ipk in <ipk_cache>/<arch>/ from a prior full build (build-immortalwrt.yml).

set -euo pipefail

DEVICE="${1:?device}"
ROOT="${2:?config root}"
WORKSPACE="${3:?workspace}"
IPK_CACHE="${4:?ipk cache dir}"
OUT_DIR="${5:?output dir}"
IB_BASE="${IB_BASE:-https://downloads.immortalwrt.org/snapshots}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$ROOT/immortalwrt/${DEVICE}.config"
[ -f "$CFG" ] || { echo "ERROR: missing $CFG" >&2; exit 1; }

ARCH="$("$SCRIPT_DIR/imagebuilder-arch.sh" "$CFG")"
IPK_SRC="$("$SCRIPT_DIR/resolve-ipk-cache.sh" "$CFG" "$IPK_CACHE")"
echo "    ipk cache: $IPK_SRC"
PROFILE="$(grep -E '^CONFIG_TARGET_.*_DEVICE_.*=y' "$CFG" | head -1 | sed -E 's/^CONFIG_TARGET_.*_DEVICE_(.*)=y/\1/')"

if grep -q '^CONFIG_TARGET_x86_64=y' "$CFG"; then
  TARGET=x86
  SUBTARGET=64
  PROFILE="${PROFILE:-generic}"
else
  line="$(grep -E '^CONFIG_TARGET_[a-z0-9]+_[a-z0-9_]+=y' "$CFG" | grep -v '_DEVICE_' | head -1)"
  TARGET="$(echo "$line" | sed -E 's/^CONFIG_TARGET_([a-z0-9]+)_.*/\1/')"
  SUBTARGET="$(echo "$line" | sed -E 's/^CONFIG_TARGET_[a-z0-9]+_(.*)=y/\1/')"
fi

[ -n "$PROFILE" ] || { echo "ERROR: no profile in $CFG" >&2; exit 1; }

echo "==> ImageBuilder: $DEVICE"
echo "    target: $TARGET/$SUBTARGET"
echo "    profile: $PROFILE"
echo "    arch: $ARCH"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

IB_NAME="immortalwrt-imagebuilder-${TARGET}-${SUBTARGET}.Linux-x86_64.tar.zst"
IB_URL="${IB_BASE}/targets/${TARGET}/${SUBTARGET}/${IB_NAME}"

echo "==> Download ImageBuilder"
curl -fL --retry 3 --connect-timeout 60 -o "$WORKDIR/ib.tar.zst" "$IB_URL"
tar -C "$WORKDIR" -xf "$WORKDIR/ib.tar.zst"
IB_DIR="$(find "$WORKDIR" -maxdepth 1 -type d -name 'immortalwrt-imagebuilder-*' | head -1)"
[ -n "$IB_DIR" ] || { echo "ERROR: ImageBuilder extract failed" >&2; exit 1; }

mkdir -p "$IB_DIR/packages"
cp -a "$IPK_SRC"/*.ipk "$IB_DIR/packages/"
echo "==> Injected $(find "$IB_DIR/packages" -maxdepth 1 -name '*.ipk' | wc -l) custom ipk"

FILES_DIR="$WORKDIR/overlay"
mkdir -p "$FILES_DIR"
bash "$WORKSPACE/scripts/generate-banner.sh" immortalwrt "$WORKSPACE/files"
bash "$WORKSPACE/scripts/bundle-oh-my-bash.sh" "$WORKSPACE/files"
cp -a "$WORKSPACE/files/." "$FILES_DIR/"

PACKAGES="$("$SCRIPT_DIR/imagebuilder-packages.sh" "$ROOT")"
[ -n "$PACKAGES" ] || { echo "ERROR: empty package list" >&2; exit 1; }

cd "$IB_DIR"
EXTRA=""
if grep -q '^CONFIG_TARGET_ROOTFS_PARTSIZE=' "$CFG" 2>/dev/null; then
  size="$(grep '^CONFIG_TARGET_ROOTFS_PARTSIZE=' "$CFG" | sed 's/.*=//')"
  [ -n "$size" ] && EXTRA="ROOTFS_PARTSIZE=$size"
fi

echo "==> make image PROFILE=$PROFILE"
# shellcheck disable=SC2086
make image PROFILE="$PROFILE" PACKAGES="$PACKAGES" FILES="$FILES_DIR" $EXTRA -j"$(nproc)"

mkdir -p "$OUT_DIR"
bash "$WORKSPACE/scripts/pack-firmware.sh" \
  "$DEVICE" immortalwrt "$CFG" \
  "$IB_DIR/bin/targets" "$OUT_DIR"

echo "==> ImageBuilder done: $DEVICE"
