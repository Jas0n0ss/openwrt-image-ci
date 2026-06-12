FROM ubuntu:22.04

LABEL org.opencontainers.image.description="Pre-baked OpenWrt/LEDE/ImmortalWrt build environment"

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    LANG=C.UTF-8

RUN apt-get update -qq && \
    apt-get install -y -q --no-install-recommends \
      build-essential clang flex bison g++ gawk gettext \
      git libssl-dev libelf-dev python3 python3-dev python3-distutils \
      rsync unzip zlib1g-dev file wget subversion patch upx-ucl ccache \
      ecj fastjar java-propose-classpath libncurses5-dev libncursesw5-dev \
      libz-dev curl cmake jq rename tar ca-certificates time zstd \
      sudo && \
    rm -rf /var/lib/apt/lists/*

# Allow passwordless sudo for the runner user GitHub Actions injects
RUN echo 'ALL ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Make ccache accessible on PATH
ENV PATH="/usr/lib/ccache:${PATH}"
