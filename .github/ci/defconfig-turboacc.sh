#!/usr/bin/env bash
# patch-kconfig-tree + defconfig + scrub + TurboACC oldconfig.
# Usage: defconfig-turboacc.sh <src_dir> [workspace]

set -euo pipefail
SRC="${1:?}"
WS="${2:-${GITHUB_WORKSPACE:?}}"

cd "$SRC"
PATCH="$WS/.github/ci/patch-kconfig-tree.sh"
export PATCH_OVERLAY="$WS/scripts/overlays"

bash "$PATCH" .
make defconfig > defconfig.log 2>&1 || { echo "make defconfig failed:"; cat defconfig.log; exit 1; }
if grep -q 'recursive dependency detected' defconfig.log; then
  echo "=== Kconfig recursive dependency (defconfig) ==="
  grep -E 'recursive dependency|symbol PACKAGE_' defconfig.log || true
  exit 1
fi
bash "$WS/.github/ci/scrub-config-cycles.sh" .config
bash "$PATCH" .
rm -rf tmp/.config-package.in tmp/.config-target.in tmp/.config-feeds.in 2>/dev/null || true
cat "$WS/configs/snippets/turboacc.config" >> .config
make oldconfig > oldconfig.log 2>&1 || { echo "make oldconfig failed:"; cat oldconfig.log; exit 1; }
if grep -q 'recursive dependency detected' oldconfig.log; then
  echo "=== Kconfig recursive dependency (oldconfig) ==="
  grep -E 'recursive dependency|symbol PACKAGE_' oldconfig.log || true
  exit 1
fi
