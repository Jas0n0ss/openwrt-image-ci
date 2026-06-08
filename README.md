# OpenWrt / LEDE 固件构建

[![Build firmware](https://img.shields.io/github/actions/workflow/status/Jas0n0ss/openwrt-lede-builder/build-firmware.yml?branch=main&label=firmware)](https://github.com/Jas0n0ss/openwrt-lede-builder/actions/workflows/build-firmware.yml)
[![Build ipk](https://img.shields.io/github/actions/workflow/status/Jas0n0ss/openwrt-lede-builder/build-ipk.yml?branch=main&label=ipk)](https://github.com/Jas0n0ss/openwrt-lede-builder/actions/workflows/build-ipk.yml)
[![Build LEDE](https://img.shields.io/github/actions/workflow/status/Jas0n0ss/openwrt-lede-builder/build-lede.yml?branch=main)](https://github.com/Jas0n0ss/openwrt-lede-builder/actions/workflows/build-lede.yml)
[![Build ImmortalWrt](https://img.shields.io/github/actions/workflow/status/Jas0n0ss/openwrt-lede-builder/build-immortalwrt.yml?branch=main&label=immortalwrt-full)](https://github.com/Jas0n0ss/openwrt-lede-builder/actions/workflows/build-immortalwrt.yml)
[![GitHub release](https://img.shields.io/github/v/release/Jas0n0ss/openwrt-lede-builder)](https://github.com/Jas0n0ss/openwrt-lede-builder/releases)
[![License](https://img.shields.io/github/license/Jas0n0ss/openwrt-lede-builder)](https://github.com/Jas0n0ss/openwrt-lede-builder/blob/main/LICENSE)

基于 [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede) 与 [ImmortalWrt](https://github.com/immortalwrt/immortalwrt)，通过 GitHub Actions 编译预配置固件。

## 设备

| 设备 | 代号 |
|------|------|
| 小米 AX3600 | `xiaomi-ax3600` |
| 小米 AX9000 | `xiaomi-ax9000` |
| 小米 WR30U | `xiaomi-wr30u` |
| 小米 AX6000 | `xiaomi-ax6000` |
| 红米 AX6000 | `redmi-ax6000` |
| 斐讯 K2P | `phicomm-k2p` |
| 小米 CR660x | `xiaomi-cr660x` |
| NanoPi R2S | `r2s` |
| x86_64 | `x86_64` |
| 树莓派 4B | `raspberrypi-4b` |

## CI 工作流

全量编译 job 在 `ubuntu-22.04` runner 上通过 `.github/ci/install-build-deps.sh` 安装依赖；`dl` / `feeds` / `ccache` 仍走 Actions cache。

| Workflow | 用途 | 频率 | 耗时 |
|----------|------|------|------|
| **Build ipk** | 按架构编译自定义插件 ipk（5 个 job） | 插件变更时 | 数小时 |
| **Build firmware** | ImageBuilder 日常固件（**推荐**） | 配置/overlay 变更 | ~30–60 分钟 |
| **Build ImmortalWrt** | 全量源码编译 + ipk | 高级/兜底 | 数小时 |
| **Build LEDE** | LEDE 全量源码编译 | 高级 | 数小时 |

推荐流程：

```
1. Build ipk          → 生成各架构自定义 ipk（profiles/arch-canonical.list）
2. Build firmware     → ImageBuilder 打包 10 台固件（自动拉取 ipk 缓存/产物）
```

```
Actions → 选 workflow → Run workflow → device 选 all 或单台设备
```

**仅手动触发**（push / 定时已关闭）。选择 **all** 时，所有设备固件合并到**同一个 Release**（`firmware-<编号>` / `immortalwrt-<编号>` / `lede-<编号>`）。

## 目录

| 路径 | 说明 |
|------|------|
| `.github/ci/` | CI 脚本（feeds 安装、Kconfig 修复、打包、ImageBuilder 等） |
| `configs/` | 分层 `.config`（设备 / common / 插件 / snippets） |
| `files/` | 固件 rootfs 覆盖（uci-defaults、自定义配置等） |
| `overlays/` | 用户自定义 Makefile 覆盖与 banner 模板 |
| `profiles/` | 架构与设备映射（ipk 流水线） |

## 默认凭据

| 项 | 值 |
|----|-----|
| 地址 | http://10.10.10.1 |
| 用户 | `root` |
| 密码 | `password` |

## License

[LICENSE](LICENSE)
