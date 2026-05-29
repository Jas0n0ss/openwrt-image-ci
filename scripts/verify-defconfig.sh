#!/usr/bin/env bash
# Run make defconfig; fail on Kconfig cycles or policy errors.
# Usage: verify-defconfig.sh <src_dir>

set -euo pipefail

SRC_DIR="${1:?source directory required}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$SRC_DIR"

bash "${SCRIPT_DIR}/ci-fix-kconfig-tree.sh" "$(pwd)"

[ -f .config ] || {
  echo "ERROR: .config missing in $SRC_DIR" >&2
  exit 1
}

log="$(mktemp)"
trap 'rm -f "$log"' EXIT

set +e
make defconfig >"$log" 2>&1
rc=$?
set -e

cat "$log"

if [ "$rc" -ne 0 ]; then
  echo "ERROR: make defconfig failed (exit $rc)" >&2
  exit 1
fi

if grep -q 'recursive dependency detected' "$log"; then
  echo "ERROR: Kconfig recursive dependency (see log above)" >&2
  grep 'recursive dependency detected' -A3 "$log" >&2 || true
  exit 1
fi

for bad in libselinux shadowsocks-rust naiveproxy; do
  if grep -q "^CONFIG_PACKAGE_${bad}=y" .config; then
    echo "ERROR: ${bad} must stay disabled (see configs/snippets/)" >&2
    exit 1
  fi
done

echo "==> verify-defconfig: OK (no recursive dependency)"
