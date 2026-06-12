#!/usr/bin/env bash
# Install OpenWrt/LEDE compile dependencies on ubuntu-22.04 runner.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update -qq
sudo apt-get install -y -q --no-install-recommends \
  build-essential clang flex bison g++ gawk gettext \
  git libssl-dev libelf-dev python3 python3-dev python3-distutils \
  rsync unzip zlib1g-dev file wget subversion patch upx-ucl ccache \
  ecj fastjar java-propose-classpath libncurses5-dev libncursesw5-dev \
  libz-dev curl cmake jq rename tar ca-certificates time \
  zstd
