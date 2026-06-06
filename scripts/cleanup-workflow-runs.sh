#!/usr/bin/env bash
# Delete failed and cancelled GitHub Actions workflow runs for this repository.
# Usage: cleanup-workflow-runs.sh <owner/repo>

set -euo pipefail

REPO="${1:?owner/repo}"
BATCH=100

delete_by_status() {
  local status="$1"
  local total=0

  while true; do
    mapfile -t ids < <(
      gh run list --repo "$REPO" --status "$status" --limit "$BATCH" \
        --json databaseId -q '.[].databaseId'
    )
    [ "${#ids[@]}" -eq 0 ] && break

    for id in "${ids[@]}"; do
      [ -n "$id" ] || continue
      if gh run delete "$id" --repo "$REPO" 2>/dev/null; then
        total=$((total + 1))
      fi
    done
  done

  echo "==> $status: deleted $total run(s)"
}

echo "==> Cleanup workflow runs: $REPO"

for status in failure cancelled; do
  delete_by_status "$status"
done

echo "==> Done"
