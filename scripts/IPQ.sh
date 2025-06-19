# 修改默认IP
sed -i 's/192.168.1.1/10.8.1.1/g' package/base-files/files/bin/config_generate

# 修改主机名
sed -i 's/ImmortalWrt/FOXHOUND/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/FOXHOUND/g' include/version.mk
sed -i 's/ImmortalWrt/FOXHOUND/g' package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc

# 替换 SNAPSHOT 为 (QSDK 12.2)
sed -i 's/SNAPSHOT/(QSDK 12.2 R7)/g' include/version.mk
sed -i 's/ECM:/ /g' target/linux/qualcommax/base-files/sbin/cpuusage
sed -i 's/HWE/NPU/g' target/linux/qualcommax/base-files/sbin/cpuusage

# 删除luci首页显示
sed -i '86d' feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
sed -i "s/+ ' \/ ' : '') + (luciversion ||/:/g" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# passwall2
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall2 package/luci-app-passwall2

# 修正 Makefile 路径问题
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}

# luci-theme-material3
git clone -b main --depth 1 --single-branch https://github.com/AngelaCooljx/luci-theme-material3 package/luci-theme-material3
rm -rf package/luci-theme-material3/{.git,Readme.md}
sed -i 's|../../luci.mk|$(TOPDIR)/feeds/luci/luci.mk|' package/luci-theme-material3/Makefile
sed -i '/uci -q delete luci.themes.Material3Red/a \	uci set luci.main.mediaurlbase=\x27/luci-static/bootstrap\x27' package/luci-theme-material3/Makefile
rm -rf package/luci-theme-material3/root/etc/uci-defaults/30_luci-theme-material3
echo '#!/bin/sh
if [ "$PKG_UPGRADE" != 1 ]; then
	uci get luci.themes.material3 >/dev/null 2>&1 || \
	uci batch <<-EOF
		set luci.themes.material3=/luci-static/material3
		set luci.main.mediaurlbase=/luci-static/material3
		commit luci
	EOF
fi
exit 0' > package/luci-theme-material3/root/etc/uci-defaults/30_luci-theme-material3 && chmod +x package/luci-theme-material3/root/etc/uci-defaults/30_luci-theme-material3
# luci-theme-material3

./scripts/feeds update -a
./scripts/feeds install -a

# 修改插件名字
sed -i 's/"PassWall 2"/"PassWall"/g' `egrep "PassWall 2" -rl ./`

# etc默认设置
cp -a $GITHUB_WORKSPACE/scripts/etc/* package/base-files/files/etc/

# 修改插件位置
sed -i 's/vpn/services/g' feeds/luci/applications/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json

#修改qca-nss-drv启动顺序
sed -i 's/START=.*/START=85/g' feeds/nss_packages/qca-nss-drv/files/qca-nss-drv.init

