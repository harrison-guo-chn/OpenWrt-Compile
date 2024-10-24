#!/bin/bash

#删除luci文件夹
rm -rf feeds

#修改feeds.conf.default
cat <<EOF > feeds.conf.default
src-git packages https://github.com/coolsnowwolf/packages
src-git luci https://github.com/coolsnowwolf/luci
src-git routing https://github.com/coolsnowwolf/routing
src-git telephony https://github.com/openwrt/telephony.git;openwrt-23.05
EOF

# 修改默认IP
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# TTYD 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

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

# 添加额外插件
git clone --depth=1 https://github.com/sirpdboy/netspeedtest.git package/netspeedtest
git clone --depth=1 https://github.com/tty228/luci-app-wechatpush.git package/luci-app-wechatpush
git_sparse_clone main https://github.com/kenzok8/small-package luci-app-wrtbwmon wrtbwmon

# Themes
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# 在线用户
git_sparse_clone main https://github.com/haiibo/packages luci-app-onliner
sed -i '$i uci set nlbwmon.@nlbwmon[0].refresh_interval=2s' package/lean/default-settings/files/zzz-default-settings
sed -i '$i uci commit nlbwmon' package/lean/default-settings/files/zzz-default-settings
chmod 755 package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh

./scripts/feeds update -a
./scripts/feeds install -a
