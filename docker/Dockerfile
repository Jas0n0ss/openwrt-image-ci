# OpenWrt / LEDE compile environment for GitHub Actions (ubuntu-22.04).
# Caches apt packages only; dl/feeds/ccache stay in Actions cache volumes.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV LANG=C.UTF-8

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential clang flex bison g++ gawk gettext \
    git libssl-dev libelf-dev python3 python3-dev python3-distutils \
    rsync unzip zlib1g-dev file wget subversion patch upx-ucl ccache \
    ecj fastjar java-propose-classpath libncurses5-dev libncursesw5-dev \
    libz-dev curl cmake jq rename tar ca-certificates time \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
