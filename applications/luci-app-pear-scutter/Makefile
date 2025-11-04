include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for pear_scutter
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+luci-compat

PKG_NAME:=luci-app-pearscutter
PKG_LICENSE:=MIT
PKG_MAINTAINER:=mike <mike@pear.hk>

include $(TOPDIR)/feeds/luci/luci.mk

# 如果你用的是 OpenWrt 官方 LuCI 源外的独立仓库，可能要用 include $(TOPDIR)/feeds/luci/luci.mk
# 若在本地 package 目录，请确保 feeds 更新后可见

# call BuildPackage - OpenWrt buildroot 会处理
$(eval $(call BuildPackage,$(PKG_NAME)))
