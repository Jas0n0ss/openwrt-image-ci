# Overlay: break Kconfig cycle (no conditional LUCI_DEPENDS → kmod-*).
# kmod-tcp-bbr / kmod-nft-fullcone enabled via configs/snippets/turboacc.config only.
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-turboacc
PKG_VERSION:=1.4
PKG_RELEASE:=1

PKG_LICENSE:=GPL-3.0-only
PKG_MAINTAINER:=chenmozhijin

LUCI_TITLE:=LuCI support for Flow Offload / Shortcut-FE
LUCI_DEPENDS:= +luci +luci-compat
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk
