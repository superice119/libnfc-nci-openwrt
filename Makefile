#
# Copyright (C) 2024 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libnfc-nci
PKG_VERSION:=2.0
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/NXPNFCLinux/linux_libnfc-nci.git
PKG_SOURCE_VERSION:=NCI2.0_PN7160
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_MIRROR_HASH:=e4eaf8e43c0f1a266c250fe835f6b3eed211294601053ccc306e7f6bdd260442

PKG_FIXUP:=autoreconf
PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1

PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE.txt
PKG_MAINTAINER:=OpenWrt Developer

include $(INCLUDE_DIR)/package.mk

define Package/libnfc-nci
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=NXP NFC NCI library for PN7160
  URL:=https://github.com/NXPNFCLinux/linux_libnfc-nci
  DEPENDS:=+libstdcpp +libpthread +librt +libgpiod
endef

define Package/libnfc-nci/description
  NXP NFC NCI library for PN7160 NFC controller.
  This library provides support for NFC operations on Linux systems.
endef

define Package/libnfc-nci-utils
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=NXP NFC utilities
  URL:=https://github.com/NXPNFCLinux/linux_libnfc-nci
  DEPENDS:=+libnfc-nci
endef

define Package/libnfc-nci-utils/description
  NXP NFC utilities including nfcDemoApp for PN7160 NFC controller.
endef

define Package/libpn7160-fw
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=PN7160 firmware library
  URL:=https://github.com/NXPNFCLinux/linux_libnfc-nci
  DEPENDS:=+libnfc-nci
endef

define Package/libpn7160-fw/description
  PN7160 firmware update library.
endef

#CONFIGURE_ARGS += \
	--prefix=/usr \
	--sysconfdir=/etc/nfc
CONFIGURE_ARGS += \
    --prefix=/usr \
    --sysconfdir=/etc/nfc \
    --enable-libgpiod

TARGET_CFLAGS += -D_FILE_OFFSET_BITS=64
TARGET_CXXFLAGS += -D_FILE_OFFSET_BITS=64

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/* $(1)/usr/include/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/*.so* $(1)/usr/lib/
	-$(CP) $(PKG_INSTALL_DIR)/usr/lib/*.a $(1)/usr/lib/ 2>/dev/null || true	
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/pkgconfig/*.pc $(1)/usr/lib/pkgconfig/
endef

define Package/libnfc-nci/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libnfc_nci* $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/etc/nfc
	$(INSTALL_DATA) ./files/libnfc-nci.conf $(1)/etc/nfc/
	$(INSTALL_DATA) ./files/libnfc-nxp.conf $(1)/etc/nfc/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/nfc.config $(1)/etc/config/nfc
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/nfc.init $(1)/etc/init.d/nfc
endef

define Package/libnfc-nci-utils/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/nfcDemoApp $(1)/usr/sbin/
	$(INSTALL_BIN) ./files/nfc-helper $(1)/usr/sbin/
endef

define Package/libpn7160-fw/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libpn7160_fw.so* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libnfc-nci))
$(eval $(call BuildPackage,libnfc-nci-utils))
$(eval $(call BuildPackage,libpn7160-fw))
