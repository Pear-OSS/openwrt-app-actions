#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/package.mk

LLUCI_TITLE:=Fogvdn Luci App
LUCI_PKGARCH:=all
PKG_VERSION:=7
PKG_RELEASE:=$(AUTORELEASE)
LUCI_DEPENDS:=+fogvdn +jq


include $(TOPDIR)/feeds/luci/luci.mk

define Package/$(LUCI_NAME)
	SECTION:=services
	CATEGORY:=PCDN
	TITLE:=$(if $(LUCI_TITLE),$(LUCI_TITLE),LuCI $(LUCI_NAME) $(LUCI_TYPE))
	DEPENDS:=$(LUCI_DEPENDS)
	$(if $(LUCI_PKGARCH),PKGARCH:=$(LUCI_PKGARCH))
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "${IPKG_INSTROOT}" ] || {
	(. /etc/uci-defaults/30-run_post_update_cmd) && rm -f /etc/uci-defaults/30-run_post_update_cmd 
	(. /etc/uci-defaults/luci-fogvdn) && rm -f /etc/uci-defaults/luci-fogvdn
	exit 0
}
echo 1 > /tmp/fogvdn_enable_state
service fogvdn start 2>/dev/null
#endef
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
/etc/init.d/fogvdn stop
/etc/init.d/fogvdn disable
#endef
endef

$(eval $(call BuildPackage,$(LUCI_NAME)))

# call BuildPackage - OpenWrt buildroot signature
