#!/usr/bin/env bash
# Setup feeds and clone custom packages for OpenWrt/LEDE builds.
# Usage: setup-custom-packages.sh <src_dir> [append] [config_root]

set -euo pipefail

SRC_DIR="${1:?source directory required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="${3:-${SCRIPT_DIR}/../configs}"

cd "$SRC_DIR"

extract_kconfig_packages() {
  local cfg
  for cfg in "$@"; do
    [ -f "$cfg" ] || continue
    grep -E '^CONFIG_PACKAGE_[A-Za-z0-9][A-Za-z0-9._+-]*=y' "$cfg" \
      | sed 's/^CONFIG_PACKAGE_//;s/=y$//' \
      | grep -vE '_INCLUDE_|_Including_' || true
  done
}

append_feed_line() {
  local line="$1"
  line="$(echo "$line" | xargs)"
  [ -n "$line" ] || return 0
  grep -qF "$line" feeds.conf.default 2>/dev/null || echo "$line" >> feeds.conf.default
}

install_pkg() {
  local pkg="$1"
  if [ -f "package/${pkg}/Makefile" ]; then
    return 0
  fi
  ./scripts/feeds install "$pkg" 2>/dev/null
}

clone_repo() {
  local dest="$1"
  shift
  rm -rf "$dest"
  git clone --depth 1 "$@" "$dest"
}

verify_makefile() {
  local path="$1"
  local name="$2"
  [ -f "$path" ] || {
    echo "ERROR: ${name} install failed (no ${path})" >&2
    exit 1
  }
}

pin_pkg_makefile() {
  local mk="$1" ver="$2" hash="$3" label="$4"
  [ -f "$mk" ] || {
    echo "ERROR: missing ${mk} (PassWall feed not installed?)" >&2
    exit 1
  }
  if grep -q "PKG_VERSION:=${ver}" "$mk"; then
    echo "==> ${label} already at ${ver}"
    return 0
  fi
  sed -i \
    -e "s/^PKG_VERSION:=.*/PKG_VERSION:=${ver}/" \
    -e "s/^PKG_HASH:=.*/PKG_HASH:=${hash}/" \
    "$mk"
  echo "==> Pinned ${label} to ${ver} (golang/host 1.21 compatible)"
}

patch_feeds() {
  pin_pkg_makefile \
    "feeds/passwall_packages/xray-core/Makefile" \
    "24.12.31" \
    "e3c24b561ab422785ee8b7d4a15e44db159d9aa249eb29a36ad1519c15267be" \
    "xray-core"
  pin_pkg_makefile \
    "feeds/passwall_packages/sing-box/Makefile" \
    "1.11.0" \
    "d4a48b2fe450041fea2d25955ddc092a62afc8da7bb442b49cb12575123b2edb" \
    "sing-box"

  local dir mk name feed
  for dir in \
    feeds/luci/applications/luci-app-passwall \
    package/feeds/luci/luci-app-passwall; do
    [ -e "$dir" ] || continue
    rm -rf "$dir"
    echo "==> Removed duplicate luci-app-passwall: ${dir}"
  done

  for mk in \
    feeds/passwall_luci/luci-app-passwall/Makefile \
    package/feeds/passwall_luci/luci-app-passwall/Makefile; do
    [ -f "$mk" ] || continue
    if grep -q '+dnsmasq-full' "$mk"; then
      sed -i 's/+dnsmasq-full/+dnsmasq/g' "$mk"
      echo "==> Patched ${mk}: dnsmasq-full -> dnsmasq"
    fi
  done

  for name in luci-app-unblockneteasemusic nftables-json nftables-nojson; do
    while IFS= read -r dir; do
      [ -n "$dir" ] || continue
      rm -rf "$dir"
      echo "==> Removed conflicting feed package: ${dir}"
    done < <(find feeds package/feeds package -type d -name "$name" 2>/dev/null || true)
  done

  for feed in feeds/kenzo feeds/small package/feeds/kenzo package/feeds/small; do
    [ -d "$feed" ] || continue
    while IFS= read -r dir; do
      [ -n "$dir" ] || continue
      rm -rf "$dir"
      echo "==> Removed stale luci-ssl: ${dir}"
    done < <(find "$feed" -type d -name luci-ssl 2>/dev/null || true)
  done
}

verify_setup() {
  [ -f feeds/passwall_packages/xray-core/Makefile ] \
    || { echo "ERROR: missing passwall xray-core" >&2; exit 1; }
  grep -q 'PKG_VERSION:=24.12.31' feeds/passwall_packages/xray-core/Makefile \
    || { echo "ERROR: xray-core not pinned to 24.12.31" >&2; exit 1; }
  [ -f feeds/passwall_packages/sing-box/Makefile ] \
    || { echo "ERROR: missing sing-box" >&2; exit 1; }
  grep -q 'PKG_VERSION:=1.11.0' feeds/passwall_packages/sing-box/Makefile \
    || { echo "ERROR: sing-box not pinned to 1.11.0" >&2; exit 1; }
  if [ ! -f feeds/passwall_luci/luci-app-passwall/Makefile ] \
    && [ ! -f package/feeds/passwall_luci/luci-app-passwall/Makefile ]; then
    echo "ERROR: luci-app-passwall not installed" >&2
    exit 1
  fi
  if [ ! -f feeds/luci/luci-ssl/Makefile ] \
    && [ ! -f package/feeds/luci/luci-ssl/Makefile ]; then
    echo "ERROR: luci-ssl missing" >&2
    exit 1
  fi
  for pkg in luci-app-mosdns luci-app-turboacc luci-theme-aurora luci-app-arpbind; do
    [ -f "package/${pkg}/Makefile" ] || {
      echo "ERROR: missing package/${pkg}/Makefile" >&2
      exit 1
    }
  done
  [ -f package/nft-fullcone/Makefile ] \
    || { echo "ERROR: missing package/nft-fullcone" >&2; exit 1; }
}

echo "==> Appending PassWall feeds to feeds.conf.default"
if [ ! -f feeds.conf.default ]; then
  echo "ERROR: feeds.conf.default not found in $(pwd)" >&2
  exit 1
fi

PASSWALL_FEEDS='
src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main
src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;main
'
while IFS= read -r line; do append_feed_line "$line"; done << EOF
${PASSWALL_FEEDS}
EOF

./scripts/feeds update -a

echo "==> Removing conflicting feed packages"
rm -rf feeds/luci/luci-app-dae feeds/luci/luci-app-daed 2>/dev/null || true
# LEDE luci feed ships luci-app-passwall (needs tuic-client); use passwall_luci only
rm -rf feeds/luci/applications/luci-app-passwall package/feeds/luci/luci-app-passwall 2>/dev/null || true
while IFS= read -r dir; do
  [ -n "$dir" ] || continue
  rm -rf "$dir"
done < <(find feeds -name '*fchomo*' -type d 2>/dev/null || true)

echo "==> Installing transitive feed dependencies"
FEED_DEPS=(
  wsdd2 luci-app-ksmbd luci-app-samba luci-app-samba4
  ddns-scripts wget-ssl bash
  ntpdate smartmontools gperf
  libnetsnmp libtins libyaml-cpp libgpiod libtirpc libaio
)
for pkg in "${FEED_DEPS[@]}"; do
  install_pkg "$pkg" || echo "    skip feed dep: ${pkg}"
done

echo "==> Installing PassWall feeds (required)"
./scripts/feeds install -p passwall_packages
./scripts/feeds install -p passwall_luci

echo "==> Installing base feed packages (optional failures ignored)"
BASE_PACKAGES=(
  maccalc wireless-regdb iw luci-ssl
  luci-i18n-passwall-zh-cn luci-i18n-opkg-zh-cn luci-i18n-ttyd-zh-cn luci-i18n-arpbind-zh-cn
  kmod-mt7615-firmware kmod-mt7915-firmware
  kmod-tcp-bbr
  pcre2 libpcre2 libpcre2-8 libxml2 libunistring
  libev libsodium c-ares libcurl libudns
  boost boost-system boost-program_options boost-date_time
  coreutils coreutils-nohup unzip bc pciutils lm-sensors jq yq
  libpam zoneinfo-all
  luci-compat luci-proto-ipv6 luci-lua-runtime
  ttyd luci-app-ttyd libwebsockets-full libuv libjson-c libcap
  kmod-nft-core kmod-nf-conntrack
  jsonfilter v2ray-geoip v2ray-geosite
  golang
)
for pkg in "${BASE_PACKAGES[@]}"; do
  install_pkg "$pkg" || echo "    skip optional feed package: ${pkg}"
done

echo "==> Patching feeds (Go pins, Kconfig cycle fixes)"
patch_feeds

echo "==> Cloning custom packages into package/"
mkdir -p package
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

if [ ! -d package/luci-app-mosdns ]; then
  clone_repo "$TMPDIR/mosdns-src" -b v5 https://github.com/sbwml/luci-app-mosdns
  cp -a "$TMPDIR/mosdns-src/luci-app-mosdns" "$TMPDIR/mosdns-src/mosdns" "$TMPDIR/mosdns-src/v2dat" package/
  verify_makefile package/luci-app-mosdns/Makefile "MosDNS"
  verify_makefile package/mosdns/Makefile "mosdns"
  echo "    installed MosDNS"
fi

if [ ! -d package/luci-app-turboacc ] || [ ! -d package/nft-fullcone ]; then
  rm -rf package/luci-app-turboacc package/nft-fullcone 2>/dev/null || true
  clone_repo "$TMPDIR/turboacc-luci" -b luci https://github.com/chenmozhijin/turboacc
  clone_repo "$TMPDIR/turboacc-pkg" -b package https://github.com/chenmozhijin/turboacc
  cp -a "$TMPDIR/turboacc-luci/luci-app-turboacc" package/
  cp -a "$TMPDIR/turboacc-pkg/nft-fullcone" package/
  verify_makefile package/luci-app-turboacc/Makefile "TurboACC LuCI"
  verify_makefile package/nft-fullcone/Makefile "nft-fullcone kernel module"
  echo "    installed TurboACC (luci-app-turboacc + nft-fullcone)"
fi

if [ ! -d package/luci-theme-aurora ]; then
  clone_repo package/luci-theme-aurora https://github.com/eamonxg/luci-theme-aurora.git
  verify_makefile package/luci-theme-aurora/Makefile "Aurora"
  echo "    installed Aurora theme"
fi

if [ ! -d package/luci-app-arpbind ]; then
  clone_repo "$TMPDIR/immortal-luci" --filter=blob:none --sparse https://github.com/immortalwrt/luci
  (
    cd "$TMPDIR/immortal-luci"
    git sparse-checkout set applications/luci-app-arpbind
  )
  cp -a "$TMPDIR/immortal-luci/applications/luci-app-arpbind" package/
  verify_makefile package/luci-app-arpbind/Makefile "luci-app-arpbind"
  echo "    installed luci-app-arpbind"
fi

echo "==> Installing feed packages referenced in builder configs"
CONFIG_FILES=(
  "$CONFIG_ROOT/lede/common.config"
  "$CONFIG_ROOT/immortalwrt/common.config"
  "$CONFIG_ROOT/custom-plugins.config"
  "$CONFIG_ROOT/snippets/turboacc.config"
)
for cfg in "${CONFIG_FILES[@]}"; do
  [ -f "$cfg" ] || continue
  while IFS= read -r pkg; do
    [ -n "$pkg" ] || continue
    case "$pkg" in
      nftables-json|nftables-nojson) continue ;;
      luci-app-turboacc|kmod-nft-fullcone|kmod-nft-offload) continue ;;
    esac
    install_pkg "$pkg" || echo "    skip config package: ${pkg}"
  done < <(extract_kconfig_packages "$cfg")
done

verify_setup
echo "==> Custom package setup finished"
