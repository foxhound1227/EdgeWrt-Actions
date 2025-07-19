# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# PassWall2-Sing-Box版
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall2 package/luci-app-passwall2
sed -i '/geosite/d' package/luci-app-passwall2/luci-app-passwall2/Makefile
sed -i 's/Core/Sing-Box/g' package/luci-app-passwall2/luci-app-passwall2/luasrc/view/passwall2/global/status.htm
sed -i '74s/Xray/sing-box/g' package/luci-app-passwall2/luci-app-passwall2/root/usr/share/passwall2/0_default_config
sed -i '10,42d' package/luci-app-passwall2/luci-app-passwall2/luasrc/model/cbi/passwall2/client/rule.lua
sed -i '/Geo View/d' package/luci-app-passwall2/luci-app-passwall2/luasrc/controller/passwall2.lua
sed -i '/App Update/d' package/luci-app-passwall2/luci-app-passwall2/luasrc/controller/passwall2.lua
sed -i '/Access control/d' package/luci-app-passwall2/luci-app-passwall2/luasrc/controller/passwall2.lua
sed -i '/Other Settings/d' package/luci-app-passwall2/luci-app-passwall2/luasrc/controller/passwall2.lua
sed -i '/nofile/a\	procd_set_param limits memory="100000 150000"' feeds/packages/net/sing-box/files/sing-box.init
# 预制Sing-Box数据库
wget -P package/base-files/files/usr/share/singbox https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.db
wget -P package/base-files/files/usr/share/singbox https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.db

# 修正 Makefile 路径问题
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}

# 修改默认IP
sed -i 's/192.168.1.1/192.168.12.1/g' package/base-files/files/bin/config_generate

# 修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-argon/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
sed -i "s/primary:#5e72e4/primary:#7ca7bf/g" $(find ./feeds/luci/themes/luci-theme-argon/ -type f -name "cascade.css")

# 修改主机名
sed -i 's/ImmortalWrt/QWRT/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/QWRT/g' include/version.mk
sed -i 's/ImmortalWrt/QWRT/g' package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc

# 删除luci首页平台显示
sed -i '/Target Platform/d' feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
sed -i "s/+ ' \/ ' : '') + (luciversion ||/:/g" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js

# 替换 24.10-SNAPSHOT 为 空
sed -i 's/24.10-SNAPSHOT/ /g' include/version.mk

# 关闭RFC1918
sed -i 's/option rebind_protection 1/option rebind_protection 0/g' package/network/services/dnsmasq/files/dhcp.conf

# 修改插件位置
sed -i 's/vpn/services/g' feeds/luci/applications/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json

# 修改插件名字
sed -i 's/"PassWall 2"/"Sing-Box"/g' `egrep "PassWall 2" -rl ./`

# etc默认设置
cp -a $GITHUB_WORKSPACE/scripts/etc/* package/base-files/files/etc/

# 修改WIFI设置
sed -i 's/ImmortalWrt/QWRT/g' package/mtk/applications/mtwifi-cfg/files/mtwifi.sh
sed -i 's/set_default disassoc_low_ack 1/set_default disassoc_low_ack 0/g' package/network/config/wifi-scripts/files/lib/netifd/hostapd.sh
sed -i 's/set_default skip_inactivity_poll 0/set_default skip_inactivity_poll 1/g' package/network/config/wifi-scripts/files/lib/netifd/hostapd.sh


./scripts/feeds update -a
./scripts/feeds install -a
