#!/usr/bin/env bash
# Collect final firmware images only, rename with source + device + platform from .config.
# Usage: pack-firmware.sh <device_key> <source> <device.config> <bin/targets> <output_dir>

set -euo pipefail

DEVICE_KEY="${1:?device key}"
SOURCE="${2:?lede or immortalwrt}"
CONFIG_FILE="${3:?device .config}"
BIN_TARGETS="${4:?bin/targets}"
OUT_DIR="${5:?output dir}"

case "$SOURCE" in lede|immortalwrt) ;; *)
  echo "ERROR: source must be lede or immortalwrt" >&2; exit 1 ;; esac
[ -f "$CONFIG_FILE" ] || { echo "ERROR: config not found: $CONFIG_FILE" >&2; exit 1; }

mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR"/*

DEVICE_SLUG=""
PLATFORM_SLUG=""
if line=$(grep -E '^CONFIG_TARGET_.*_DEVICE_.*=y' "$CONFIG_FILE" | head -1); then
  DEVICE_SLUG=$(echo "$line" | sed -E 's/^CONFIG_TARGET_.*_DEVICE_(.*)=y/\1/' | tr '_' '-')
  PLATFORM_SLUG=$(echo "$line" | sed -E 's/^CONFIG_TARGET_(.*)_DEVICE_.*/\1/' | tr '_' '-')
else
  DEVICE_SLUG="$DEVICE_KEY"
  mapfile -t targets < <(grep -E '^CONFIG_TARGET_[A-Za-z0-9_]+=y' "$CONFIG_FILE" \
    | grep -v '_DEVICE_' | grep -v 'ROOTFS' | grep -v 'KERNEL' | grep -v 'IMAGES' \
    | sed -E 's/^CONFIG_TARGET_(.*)=y/\1/' | tr '_' '-' | grep -v '^y$' || true)
  PLATFORM_SLUG=$([ "${#targets[@]}" -gt 0 ] && (IFS=-; echo "${targets[*]}") || echo unknown)
fi
[ "$DEVICE_KEY" = "x86_64" ] && DEVICE_SLUG=generic && PLATFORM_SLUG=x86-64
[ -z "$DEVICE_SLUG" ] && DEVICE_SLUG="$DEVICE_KEY"

sanitize() { echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g; s/--*/-/g; s/^-//; s/-$//'; }
DEVICE_KEY_S=$(sanitize "$DEVICE_KEY")
SOURCE_S=$(sanitize "$SOURCE")
DEVICE_SLUG_S=$(sanitize "$DEVICE_SLUG")
PLATFORM_S=$(sanitize "$PLATFORM_SLUG")

is_firmware_image() {
  local base="$1"
  case "$base" in
    *.manifest|*.json|*buildinfo*|sha256*|md5*|*.dtb|*.dtbo|*.elf|vmlinux*|*uImage*|*zImage*|*Image.gz) return 1 ;;
    *initramfs*|*kernel.bin|*rootfs.tar*|*root.orig*|*profile*|*manifest*) return 1 ;;
  esac
  case "$base" in
    *sysupgrade*|*factory*|*combined*|*squashfs*|*.img.gz|*.img|*.vmdk|*.qcow2|*.sdcard.img) return 0 ;;
    *.bin) case "$base" in *sysupgrade*|*factory*|*squashfs*|*combined*) return 0 ;; esac; return 1 ;;
  esac
  return 1
}

variant_from_name() {
  case "$1" in
    *sysupgrade*) echo sysupgrade ;; *factory*) echo factory ;; *ext4-combined*) echo ext4-combined ;;
    *combined*) echo combined ;; *squashfs*) echo squashfs ;; *.vmdk) echo vmdk ;;
    *.qcow2) echo qcow2 ;; *.sdcard.img) echo sdcard ;; *) echo firmware ;;
  esac
}

count=0
while IFS= read -r -d '' src; do
  base=$(basename "$src")
  is_firmware_image "$base" || continue
  ext="${base##*.}"
  case "$base" in *.img.gz) ext=img.gz ;; *.tar.gz) ext=tar.gz ;; *.sdcard.img) ext=sdcard.img ;; esac
  variant=$(variant_from_name "$base")
  dest_name="Jas0n0ss-${SOURCE_S}-${DEVICE_KEY_S}-${DEVICE_SLUG_S}-${PLATFORM_S}-${variant}.${ext}"
  dest_path="${OUT_DIR}/${dest_name}"
  [ -e "$dest_path" ] && dest_name="Jas0n0ss-${SOURCE_S}-${DEVICE_KEY_S}-${DEVICE_SLUG_S}-${PLATFORM_S}-${variant}-${count}.${ext}" \
    && dest_path="${OUT_DIR}/${dest_name}"
  cp -f "$src" "$dest_path"
  echo "Packed: $dest_name  <=  $base"
  count=$((count + 1))
done < <(find "$BIN_TARGETS" -type f -print0 2>/dev/null || true)

[ "$count" -gt 0 ] || { echo "ERROR: no firmware under $BIN_TARGETS" >&2; find "$BIN_TARGETS" -type f 2>/dev/null | head -20; exit 1; }
echo "Packed $count file(s) into $OUT_DIR"
