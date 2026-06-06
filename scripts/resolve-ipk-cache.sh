#!/usr/bin/env bash
# Find directory with custom ipk for ImageBuilder (predicted arch + fallbacks).
# Usage: resolve-ipk-cache.sh <device.config> <ipk_cache_root>
# Prints absolute path to arch dir containing *.ipk

set -euo pipefail

CFG="${1:?device config}"
CACHE="${2:?ipk cache root}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

predicted="$("$SCRIPT_DIR/imagebuilder-arch.sh" "$CFG")"

try_dir() {
  local dir="$1"
  [ -d "$dir" ] && [ -n "$(find "$dir" -maxdepth 1 -name '*.ipk' -print -quit 2>/dev/null)" ]
}

if try_dir "$CACHE"; then
  echo "$CACHE"
  exit 0
fi

if try_dir "$CACHE/$predicted"; then
  echo "$CACHE/$predicted"
  exit 0
fi

# Common ImmortalWrt arch aliases
for alt in mips_24kc mipsel_24kc aarch64_cortex-a53 aarch64_generic aarch64_cortex-a72 x86_64; do
  if try_dir "$CACHE/$alt"; then
    echo "$CACHE/$alt"
    exit 0
  fi
done

# Any cached arch dir with ipk
while IFS= read -r dir; do
  [ -n "$dir" ] || continue
  if try_dir "$dir"; then
    echo "$dir"
    exit 0
  fi
done < <(find "$CACHE" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

echo "ERROR: no custom ipk under $CACHE (run Build ImmortalWrt full build first)" >&2
exit 1
