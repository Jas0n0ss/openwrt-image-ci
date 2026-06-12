#!/usr/bin/env bash
# Device / arch helpers. Source from other CI scripts.

arch_from_config() {
  local cfg="$1"
  if grep -q '^CONFIG_TARGET_x86_64=y' "$cfg"; then echo x86_64
  elif grep -q '^CONFIG_TARGET_qualcommax_ipq807x=y' "$cfg"; then echo aarch64_cortex-a53
  elif grep -q '^CONFIG_TARGET_mediatek_filogic=y' "$cfg"; then echo aarch64_cortex-a53
  elif grep -q '^CONFIG_TARGET_ramips_mt7621=y' "$cfg"; then echo mipsel_24kc
  elif grep -q '^CONFIG_TARGET_rockchip_armv8=y' "$cfg"; then echo aarch64_generic
  elif grep -q '^CONFIG_TARGET_bcm27xx_bcm2711=y' "$cfg"; then echo aarch64_cortex-a72
  else echo "ERROR: unknown target in $cfg" >&2; return 1; fi
}

list_devices() {
  sed 's/#.*//' "${1:-configs/devices.list}" | xargs -n1 | grep -v '^$' || true
}

device_matrix_json() {
  local pick="${1:-all}"
  local -a all=()
  mapfile -t all < <(list_devices)
  if [ "$pick" = "all" ] || [ -z "$pick" ]; then
    printf '"%s",' "${all[@]}" | sed 's/,$//'
  else
    local d
    for d in "${all[@]}"; do
      [ "$d" = "$pick" ] && { echo "\"$pick\""; return 0; }
    done
    echo "ERROR: unknown device '$pick'" >&2
    return 1
  fi
}

canonical_device_for_arch() {
  local arch="$1"
  local list="${2:-profiles/arch-canonical.list}"
  local a dev
  while read -r a dev; do
    [ -n "$a" ] || continue
    [[ "$a" =~ ^# ]] && continue
    [ "$a" = "$arch" ] && { echo "$dev"; return 0; }
  done < "$list"
  echo "ERROR: no canonical device for arch $arch" >&2
  return 1
}
