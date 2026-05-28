#!/usr/bin/env bash
# Standard firmware compile with explicit failure propagation.
# Usage: ci-compile.sh <src_dir> [toolchain_first]
#   toolchain_first: run make toolchain/compile before full build (ImmortalWrt)

set -euo pipefail

SRC_DIR="${1:?source directory required}"
TOOLCHAIN_FIRST="${2:-}"

cd "$SRC_DIR"
export PATH="/usr/lib/ccache:${PATH:-}"
ulimit -n 65535 || true

ccache -s 2>/dev/null || true

make download -j16 || make download -j8

if [ "$TOOLCHAIN_FIRST" = "1" ]; then
  make toolchain/compile -j"$(nproc)" || make toolchain/compile -j1 V=s
fi

if make -j"$(nproc)"; then
  echo "==> Build succeeded"
else
  echo "==> Parallel build failed, retrying -j1 V=s..."
  make -j1 V=s
fi

ccache -s 2>/dev/null || true
