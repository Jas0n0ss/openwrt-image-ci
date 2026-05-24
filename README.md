# OpenWrt 自动编译项目

## 快速开始

1. **Fork 本项目到你的 GitHub**

2. **启用 Actions**
   - Settings -> Actions -> General -> Allow all actions

3. **触发编译**
   - 手动: Actions -> Build OpenWrt -> Run workflow
   - 自动: 每周日自动编译

## 编译结果

- **管理地址**: http://10.10.10.1
- **用户名**: root  
- **密码**: password

## 支持的设备

- **R2S** - FriendlyARM NanoPi R2S
- **CR660x** - 小米路由器 CR6606/6608/6609
- **X86_64** - 软路由/虚拟机

## 包含插件

| 插件 | 说明 |
|------|------|
| PassWall | 科学上网 |
| Adbyby Plus | 广告过滤 |
| MosDNS | DNS转发 |
| TurboACC | 网络加速 |
| TTYD | 网页终端 |
| KMS | 激活服务 |
| Watchcat | 系统监控 |
| Aurora | 主题 |

## 下载固件

编译完成后：
- **Artifacts**: Actions 页面下载（保留7天）
- **Releases**: 自动发布的版本（永久）

## 本地编译

```bash
# 克隆 LEDE
git clone https://github.com/coolsnowwolf/lede
cd lede

# 应用配置
cat ../configs/common.config > .config
cat ../configs/r2s.config >> .config
make defconfig

# 编译
make download -j$(nproc)
make -j$(nproc) V=s
