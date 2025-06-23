# 修改默认IP
sed -i 's/192.168.1.1/192.168.12.1/g' package/base-files/files/bin/config_generate

# 修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-argon/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")

# 修改主机名
sed -i 's/ImmortalWrt/QWRT/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/QWRT/g' include/version.mk
sed -i 's/ImmortalWrt/QWRT/g' package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc

# 修改WIFI设置
sed -i 's/OWRT/QWRT/g' target/linux/qualcommax/base-files/etc/uci-defaults/990_set-wireless.sh
sed -i 's/12345678/password/g' target/linux/qualcommax/base-files/etc/uci-defaults/990_set-wireless.sh
sed -i 's/set_default disassoc_low_ack 1/set_default disassoc_low_ack 0/g' package/network/config/wifi-scripts/files/lib/netifd/hostapd.sh

# 替换 SNAPSHOT 为 (QSDK 12.2)
sed -i 's/SNAPSHOT/(QSDK 12.2 R7)/g' include/version.mk
sed -i 's/ECM:/ /g' target/linux/qualcommax/base-files/sbin/cpuusage
sed -i 's/HWE/NPU/g' target/linux/qualcommax/base-files/sbin/cpuusage

# 删除luci首页显示
sed -i '86d' feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
sed -i "s/+ ' \/ ' : '') + (luciversion ||/:/g" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js

# 移除要替换的包
rm -rf feeds/luci/themes/luci-theme-argon

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# luci-theme-argon
git clone --depth=1 https://github.com/sbwml/luci-theme-argon package/luci-theme-argon
sed -i 's/primary: #5e72e4/primary: #7fdfff/g' package/luci-theme-argon/luci-theme-argon/htdocs/luci-static/argon/css/cascade.css

# passwall2
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall2 package/luci-app-passwall2


# 修正 Makefile 路径问题
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}

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

# 关闭RFC1918
sed -i 's/option rebind_protection 1/option rebind_protection 0/g' package/network/services/dnsmasq/files/dhcp.conf

