#!/usr/bin/env bash
# Repository path helpers. Source from other CI scripts.

ci_repo_root() {
  local ci_dir
  ci_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  (cd "$ci_dir/../.." && pwd)
}

ci_overlay_root() {
  local root
  root="$(ci_repo_root)"
  echo "${PATCH_OVERLAY:-${OVERLAY_ROOT:-$root/overlays}}"
}
