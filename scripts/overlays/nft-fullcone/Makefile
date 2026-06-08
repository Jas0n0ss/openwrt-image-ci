# Overlay: break Kconfig cycle (@IPV6 + PROVIDES cause self-select on duplicate registration).
# kmod enabled via configs/snippets/turboacc.config only.
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=nft-fullcone
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define KernelPackage/nft-fullcone
  SUBMENU:=Netfilter Extensions
  DEPENDS:=+kmod-nft-core +kmod-nf-conntrack +IPV6:kmod-nf-conntrack6
  TITLE:=nftables fullcone expression support
  FILES:= $(PKG_BUILD_DIR)/nft_fullcone.ko
  KCONFIG:= CONFIG_NFT_FULLCONE=y CONFIG_NF_NAT=y CONFIG_NF_NAT_IPV6=y CONFIG_NF_CONNTRACK_EVENTS=y CONFIG_NF_CONNTRACK_CHAIN_EVENTS=y
  AUTOLOAD:=$(call AutoProbe,nft_fullcone)
endef

define KernelPackage/nft-fullcone/Description
Kernel module adds the fullcone expression that you can use
to perform NAT in the RFC3489-compatible full cone SNAT flavour.
Currently only UDP traffic is supported for full-cone NAT.
For other protos FULLCONENAT is equivalent to MASQUERADE.
endef

define Build/Compile
	+$(MAKE) $(PKG_JOBS) $(KERNEL_MAKEOPTS) \
		M="$(PKG_BUILD_DIR)" \
		EXTRA_CFLAGS="$(BUILDFLAGS)" \
		$(if $(CONFIG_IPv6),EXTRA_CFLAGS+="-DCONFIG_SFE_ECM",) \
		modules
endef

$(eval $(call KernelPackage,nft-fullcone))
