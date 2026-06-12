#!/usr/bin/env bash
# Collect custom plugin ipk from a full ImmortalWrt compile tree.
# Usage: collect-ipk.sh <src_dir> <config_root> <staging_dir>
# Writes collected arch name to $GITHUB_ENV as arch= when set.

set -euo pipefail
SRC="${1:?}"
ROOT="${2:?}"
DEST="${3:?}"

cd "$SRC"
PKG_ROOT="bin/packages"
[ -d "$PKG_ROOT" ] || { echo "ERROR: $PKG_ROOT not found" >&2; exit 1; }
mapfile -t arches < <(find "$PKG_ROOT" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -u)
[ "${#arches[@]}" -gt 0 ] || { echo "ERROR: no arch under $PKG_ROOT" >&2; exit 1; }

ARCH="${arches[0]}"
arch_dir="$PKG_ROOT/$ARCH/packages"
[ -d "$arch_dir" ] || { echo "ERROR: missing $arch_dir" >&2; exit 1; }
case "$DEST" in
  */"$ARCH") out="$DEST" ;;
  *) out="$DEST/$ARCH" ;;
esac
mkdir -p "$out"
found=0

extract_pkgs() {
  local cfg
  for cfg in "$@"; do
    [ -f "$cfg" ] || continue
    grep -E '^CONFIG_PACKAGE_[A-Za-z0-9][A-Za-z0-9._+-]*=y' "$cfg" \
      | sed 's/^CONFIG_PACKAGE_//;s/=y$//' | grep -vE '_INCLUDE_|_Including_' || true
  done
}

while IFS= read -r pkg; do
  [ -n "$pkg" ] || continue
  shopt -s nullglob
  for ipk in "$arch_dir"/${pkg}*.ipk; do cp -a "$ipk" "$out/"; found=1; done
  shopt -u nullglob
done < <(extract_pkgs "$ROOT/immortalwrt/common.config" "$ROOT/custom-plugins.config" \
  "$ROOT/snippets/turboacc.config" | sort -u)

for pattern in luci-app-passwall passwall hysteria mosdns v2dat turboacc nft-fullcone \
  luci-theme-aurora luci-app-arpbind xray-core sing-box; do
  shopt -s nullglob
  for ipk in "$arch_dir"/${pattern}*.ipk; do cp -a "$ipk" "$out/"; found=1; done
  shopt -u nullglob
done

[ "$found" -eq 1 ] || { echo "ERROR: no custom ipk in $arch_dir" >&2; exit 1; }
echo "Collected ipk for $ARCH: $(find "$out" -name '*.ipk' | wc -l) files" >&2
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "arch=$ARCH" >> "$GITHUB_ENV"
fi
echo "$ARCH"
