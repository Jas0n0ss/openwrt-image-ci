# OpenWrt / LEDE 固件构建

[![Build LEDE](https://img.shields.io/github/actions/workflow/status/Jas0n0ss/openwrt-lede-builder/build-lede.yml?branch=main)](https://github.com/Jas0n0ss/openwrt-lede-builder/actions/workflows/build-lede.yml)
[![Build ImmortalWrt](https://img.shields.io/github/actions/workflow/status/Jas0n0ss/openwrt-lede-builder/build-immortalwrt.yml?branch=main)](https://github.com/Jas0n0ss/openwrt-lede-builder/actions/workflows/build-immortalwrt.yml)
[![Build ImmortalWrt Fast](https://img.shields.io/github/actions/workflow/status/Jas0n0ss/openwrt-lede-builder/build-immortalwrt-fast.yml?branch=main&label=immortalwrt-fast)](https://github.com/Jas0n0ss/openwrt-lede-builder/actions/workflows/build-immortalwrt-fast.yml)
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

## CI

编译环境使用 GHCR 预构建镜像 `ghcr.io/<owner>/<repo>/builder:22.04`（见 `docker/`），省去每次 `apt install`。首次推送 `docker/` 后先跑 **Build builder Docker image**，再跑固件构建。

| Workflow | 说明 | 耗时 |
|----------|------|------|
| **Build builder Docker image** | 发布编译环境镜像到 GHCR | 约 5 分钟 |
| **Build LEDE** | 全量编译 10 台 LEDE | 数小时 |
| **Build ImmortalWrt** | 全量编译 10 台 ImmortalWrt | 数小时 |
| **Build ImmortalWrt (Fast)** | ImageBuilder 快速打包（类似 [固件选择器](https://firmware-selector.immortalwrt.org/)） | 约 30～60 分钟 |

```
Actions → 选 workflow → Run workflow → device 选 all 或单台设备
```

**仅手动触发**（push / 定时已关闭）。可选择 **all**（10 台）或 **单台设备**（如 `r2s`）。

选择 **all** 构建时，所有设备固件会自动合并到**同一个 Release**（`lede-<编号>` / `immortalwrt-<编号>` / `immortalwrt-fast-<编号>`），也可从 Actions Artifacts 下载单台。

## 默认凭据

| 项 | 值 |
|----|-----|
| 地址 | http://10.10.10.1 |
| 用户 | `root` |
| 密码 | `password` |

## License

[LICENSE](LICENSE)
