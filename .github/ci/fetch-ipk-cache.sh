#!/usr/bin/env bash
# Restore or download custom ipk into ipk-cache/<arch>.
# Usage: fetch-ipk-cache.sh <arch> <cache_root> [github_repository]
# Exit 0 when cache is ready; exit 1 when nothing found.

set -euo pipefail
ARCH="${1:?}"
CACHE="${2:?}"
REPO="${3:-${GITHUB_REPOSITORY:?}}"

try_dir() {
  [ -d "$1" ] && [ -n "$(find "$1" -maxdepth 1 -name '*.ipk' -print -quit 2>/dev/null)" ]
}

if try_dir "$CACHE/$ARCH" || try_dir "$CACHE"; then
  echo "ipk cache ready under $CACHE"
  exit 0
fi

for alt in mips_24kc mipsel_24kc aarch64_cortex-a53 aarch64_generic aarch64_cortex-a72 x86_64; do
  try_dir "$CACHE/$alt" && { echo "ipk cache ready (alt arch $alt)"; exit 0; }
done

: "${GH_TOKEN:?GH_TOKEN required to download ipk artifacts}"
mkdir -p "$CACHE/$ARCH"
names=(
  "immortalwrt-ipk-${ARCH}"
  immortalwrt-ipk-mips_24kc
  immortalwrt-ipk-mipsel_24kc
  immortalwrt-ipk-aarch64_cortex-a53
  immortalwrt-ipk-aarch64_generic
  immortalwrt-ipk-aarch64_cortex-a72
  immortalwrt-ipk-x86_64
)

while IFS= read -r run_id; do
  [ -n "$run_id" ] || continue
  for name in "${names[@]}"; do
    rm -rf "$CACHE/$ARCH"/*
    if gh run download "$run_id" -R "$REPO" -n "$name" -D "$CACHE/$ARCH" 2>/dev/null \
      && [ -n "$(find "$CACHE/$ARCH" -name '*.ipk' -print -quit)" ]; then
      echo "Downloaded $name from run $run_id"
      exit 0
    fi
  done
done < <(gh run list --repo "$REPO" --workflow=build-ipk.yml --status=success --limit=20 \
  --json databaseId -q '.[].databaseId' 2>/dev/null; \
  gh run list --repo "$REPO" --workflow=build-immortalwrt.yml --status=success --limit=20 \
  --json databaseId -q '.[].databaseId' 2>/dev/null)

echo "ERROR: no ipk artifact — run Build ipk (or Build ImmortalWrt full) for arch $ARCH first" >&2
exit 1
