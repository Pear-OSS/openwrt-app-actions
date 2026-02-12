include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for pear_scutter
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+luci-compat

PKG_NAME:=luci-app-pearscutter
PKG_LICENSE:=MIT
PKG_MAINTAINER:=mike <mike@pear.hk>

define Package/luci-app-pearscutter/postinst
#!/bin/sh

[ -n "$$IPKG_INSTROOT" ] || {
	arch=$$(uname -m)
	case $$arch in
		x86_64)
			installation_path="/opt/pear/pear_scutter_x86_64"
			;;
		aarch64)
			installation_path="/opt/pear/pear_scutter_aarch64"
			;;
		armv7*)
			installation_path="/opt/pear/pear_scutter_armv7"
			;;
		*)
			echo "Unsupported architecture: $$arch"
			exit 1
			;;
	esac

	sed -i "s#@{installation_path_to_be_replaced}#$$installation_path#g" /etc/init.d/pear-scutter
	
	mkdir -p "$$(dirname "$$installation_path")"
	
	echo "Pear Scutter installed for architecture: $$arch"
	echo "Installation path: $$installation_path"
}
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# 如果你用的是 OpenWrt 官方 LuCI 源外的独立仓库，可能要用 include $(TOPDIR)/feeds/luci/luci.mk
# 若在本地 package 目录，请确保 feeds 更新后可见

# call BuildPackage - OpenWrt buildroot 会处理
# $(eval $(call BuildPackage,$(PKG_NAME)))