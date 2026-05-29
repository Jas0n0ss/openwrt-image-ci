#!/usr/bin/env bash
# Base defconfig + TurboACC enable + policy checks.
# Usage: verify-defconfig.sh <src_dir> <workspace>

set -euo pipefail

SRC_DIR="${1:?source directory required}"
WORKSPACE="${2:?builder repo root}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$SRC_DIR"

stash_turboacc() {
  local action="$1" stash=".ci-stash-turboacc"
  case "$action" in
    hide)
      mkdir -p "$stash"
      for d in luci-app-turboacc nft-fullcone; do
        if [ -d "package/${d}" ]; then
          rm -rf "${stash}/${d}"
          mv "package/${d}" "${stash}/${d}"
          echo "==> verify-defconfig: stashed package/${d}"
        fi
      done
      ;;
    unhide)
      for d in luci-app-turboacc nft-fullcone; do
        if [ -d "${stash}/${d}" ]; then
          rm -rf "package/${d}"
          mv "${stash}/${d}" "package/${d}"
          echo "==> verify-defconfig: restored package/${d}"
        fi
      done
      ;;
    *)
      echo "ERROR: stash_turboacc unknown action '${action}'" >&2
      exit 1
      ;;
  esac
}

bash "${SCRIPT_DIR}/ci-fix-kconfig-tree.sh" "$(pwd)"
stash_turboacc hide

[ -f .config ] || {
  echo "ERROR: .config missing in $SRC_DIR" >&2
  exit 1
}

log="$(mktemp)"
restored_turboacc=0
cleanup() {
  rm -f "$log"
  if [ "$restored_turboacc" -eq 0 ]; then
    stash_turboacc unhide >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

echo "==> verify-defconfig: base make defconfig (TurboACC packages stashed)"
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
  echo "ERROR: Kconfig recursive dependency during base defconfig" >&2
  grep 'recursive dependency detected' -A3 "$log" >&2 || true
  exit 1
fi

stash_turboacc unhide
restored_turboacc=1
bash "${SCRIPT_DIR}/ci-fix-kconfig-tree.sh" "$(pwd)"
bash "${SCRIPT_DIR}/ci-enable-turboacc.sh" "$(pwd)" "$WORKSPACE"

for bad in libselinux shadowsocks-rust naiveproxy; do
  if grep -q "^CONFIG_PACKAGE_${bad}=y" .config; then
    echo "ERROR: ${bad} must stay disabled (see configs/snippets/)" >&2
    exit 1
  fi
done

echo "==> verify-defconfig: OK (base + TurboACC)"
