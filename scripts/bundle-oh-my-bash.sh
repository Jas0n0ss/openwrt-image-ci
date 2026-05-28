#!/usr/bin/env bash
# Bundle oh-my-bash into files/ overlay for firmware (no runtime git clone).
# Usage: bundle-oh-my-bash.sh <files_overlay_dir>

set -euo pipefail

FILES_ROOT="${1:?files overlay directory required}"
OMB_DIR="$FILES_ROOT/etc/oh-my-bash"
OMB_REPO="${OMB_REPO:-https://github.com/ohmybash/oh-my-bash.git}"
OMB_BRANCH="${OMB_BRANCH:-master}"

if [ -d "$OMB_DIR/oh-my-bash.sh" ]; then
  echo "oh-my-bash already bundled at $OMB_DIR"
  exit 0
fi

mkdir -p "$(dirname "$OMB_DIR")"
rm -rf "$OMB_DIR"

echo "==> Cloning oh-my-bash into $OMB_DIR"
git clone --depth 1 --branch "$OMB_BRANCH" "$OMB_REPO" "$OMB_DIR"
rm -rf "$OMB_DIR/.git"

echo "==> oh-my-bash bundled ($(du -sh "$OMB_DIR" | awk '{print $1}'))"
