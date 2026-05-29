# OpenWrt / LEDE 固件构建

[![Build OpenWrt](https://img.shields.io/github/actions/workflow/status/Jas0n0ss/openwrt-lede-builder/build.yml?branch=main)](https://github.com/Jas0n0ss/openwrt-lede-builder/actions/workflows/build.yml)
[![Build v2](https://img.shields.io/github/actions/workflow/status/Jas0n0ss/openwrt-lede-builder/build-v2.yml?branch=main&label=build-v2)](https://github.com/Jas0n0ss/openwrt-lede-builder/actions/workflows/build-v2.yml)
[![SDK Build](https://img.shields.io/github/actions/workflow/status/Jas0n0ss/openwrt-lede-builder/build-sdk.yml?branch=main&label=sdk)](https://github.com/Jas0n0ss/openwrt-lede-builder/actions/workflows/build-sdk.yml)
[![GitHub release](https://img.shields.io/github/v/release/Jas0n0ss/openwrt-lede-builder)](https://github.com/Jas0n0ss/openwrt-lede-builder/releases)
[![License](https://img.shields.io/github/license/Jas0n0ss/openwrt-lede-builder)](https://github.com/Jas0n0ss/openwrt-lede-builder/blob/main/LICENSE)

基于 [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede) 与 [ImmortalWrt](https://github.com/immortalwrt/immortalwrt)，通过 GitHub Actions 编译预配置固件。插件与 overlay 由本仓库统一管理。

## 特性

- **现代 CI 架构**：基于 `openwrt/gh-action-sdk` 最佳实践
- **复合操作**：可复用的 GitHub Actions 组件 (`setup-feeds`, `pack-release`)
- **多工作流支持**：
  - `build.yml` - 原版完整编译工作流
  - `build-v2.yml` - 新版现代化工作流（推荐）
  - `build-sdk.yml` - SDK 容器快速编译
- **智能缓存**：多级缓存策略 (dl, feeds, ccache)
- **自动上游检测**：每 6 小时检查上游更新并自动触发编译

## 设备

代号定义见 [`configs/devices.list`](configs/devices.list)，与 `configs/{lede,immortalwrt}/<代号>.config` 对应。

| 设备 | 代号 | 平台 |
|------|------|------|
| 小米 AX3600 | `xiaomi-ax3600` | qualcommax / ipq807x |
| 小米 AX9000 | `xiaomi-ax9000` | qualcommax / ipq807x |
| 小米 WR30U | `xiaomi-wr30u` | mediatek / filogic mt7981 |
| 小米 AX6000 | `xiaomi-ax6000` | mediatek / filogic mt7986 |
| 红米 AX6000 | `redmi-ax6000` | mediatek / filogic mt7986 |
| 斐讯 K2P | `phicomm-k2p` | ramips / mt7621 |
| 小米路由 3G | `xiaomi-3g` | ramips / mt7621 |
| 小米 CR660x | `xiaomi-cr660x` | ramips / mt7621 |
| NanoPi R2S | `r2s` | rockchip / armv8 |
| x86_64 | `x86_64` | x86_64 / generic |
| 树莓派 4B | `raspberrypi-4b` | bcm27xx / bcm2711 |

## 产物

Release / Artifacts 包含可刷写镜像，命名格式：

```
Jas0n0ss-<lede|immortalwrt>-<代号>-<设备名>-<平台>-<类型>.<后缀>
```

示例：`Jas0n0ss-lede-r2s-nanopi-r2s-rockchip-armv8-sysupgrade.img.gz`

## 预装内容

| 类别 | 内容 |
|------|------|
| 插件 | PassWall、MosDNS、TurboACC（BBR + nft-fullcone）、TTYD、ARP 绑定、Aurora 主题 |
| 语言 | LuCI 默认 **简体中文** |
| 网络 | LAN `10.10.10.1`，DHCP `10.10.10.100-250` |
| 主题 | Aurora 主题，自定义 SSH Banner |

## 默认凭据

| 项 | 值 |
|----|-----|
| 地址 | http://10.10.10.1 |
| 用户 | `root` |
| 密码 | `password` |
| 时区 | Asia/Shanghai |

## CI 工作流

### Build Firmware v2 (推荐)

现代化工作流，基于 GitHub Actions 最佳实践重构。

**参数：**
| 参数 | 选项 | 说明 |
|------|------|------|
| `source` | `immortalwrt` / `lede` | 源码选择 |
| `device` | `all` / 具体设备名 | 编译设备 |
| `build_mode` | `firmware` / `toolchain-only` | 编译模式 |
| `enable_release` | `true` / `false` | 创建 GitHub Release |
| `debug_mode` | `true` / `false` | 调试模式（禁用 fail-fast）|

**使用：**
```bash
# Actions → Build Firmware v2 → Run workflow
```

**架构改进：**
- 复合操作 (`setup-feeds`, `pack-release`) - 代码复用
- 更清晰的 job 分离 (setup → build → release)
- 改进的缓存策略，支持缓存 key 版本控制
- 更灵活的输入参数
- 更好的错误处理和调试支持

### Build Packages (SDK)

使用官方 SDK 容器快速编译单个包（基于 `openwrt/gh-action-sdk`）。

**适用场景：**
- 快速测试单个包编译
- 不需要完整固件时节省时间
- 多架构并行编译

**参数：**
| 参数 | 示例 | 说明 |
|------|------|------|
| `source` | `immortalwrt` | SDK 来源 |
| `version` | `openwrt-23.05` | SDK 版本 |
| `arch` | `x86_64` | 目标架构 |
| `packages` | `passwall` | 要编译的包 |

### Build Firmware (原版)

原始完整编译工作流，保留兼容。

### Check Upstream

自动检查上游更新：
- 每 6 小时检查一次
- LEDE 或 ImmortalWrt 有更新时自动触发全部设备编译
- 使用缓存避免重复触发

## 目录结构

```
.github/
  workflows/
    build.yml              # 原版工作流
    build-v2.yml           # 新版工作流（推荐）
    build-sdk.yml          # SDK 容器编译
    check-upstream-v2.yml  # 上游检查
  actions/
    setup-feeds/           # 复合操作：设置 feeds
    pack-release/          # 复合操作：打包发布
configs/
  devices.list             # 设备列表
  lede/  immortalwrt/      # 设备配置
  custom-plugins.config    # 插件配置
  snippets/                # 配置片段
scripts/
  setup-custom-packages.sh # feeds 与第三方包
  pack-firmware.sh         # 产物打包
  generate-banner.sh       # banner 生成
  ...
files/                     # 固件 overlay
```

## 本地编译

```bash
git clone https://github.com/coolsnowwolf/lede.git && cd lede
REPO=/path/to/openwrt-lede-builder
DEVICE=redmi-ax6000

bash "$REPO/scripts/setup-custom-packages.sh" "$(pwd)" append "$REPO/configs"
bash "$REPO/scripts/generate-banner.sh" lede "$REPO/files"
bash "$REPO/scripts/bundle-oh-my-bash.sh" "$REPO/files"
bash "$REPO/scripts/install-files-overlay.sh" "$(pwd)" "$REPO/files"

cat "$REPO/configs/lede/common.config" > .config
cat "$REPO/configs/lede/${DEVICE}.config" >> .config
cat "$REPO/configs/custom-plugins.config" >> .config
make defconfig && make download -j8 && make -j"$(nproc)" V=s
```

## 文档

- [编译加速](docs/build-speed.md) - 缓存策略和优化技巧
- [CI 排错](docs/ci-notes.md) - 常见问题排查

## License

[LICENSE](LICENSE)
