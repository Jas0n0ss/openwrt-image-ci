# 全量编译加速说明（保留全部插件）

本仓库 **不做 Image Builder 裁剪**，始终全量编译 PassWall、MosDNS、TurboACC 等自定义插件。加速仅依赖 **缓存 + ccache**。

## 已启用的缓存策略

| 缓存 | 作用范围 | 说明 |
|------|----------|------|
| `dl/` | 同一源码树下 **所有设备共享** | 减少重复下载 tarball |
| `feeds/` | 同一源码树下 **所有设备共享** | 跳过重复的 `feeds update/install` |
| `~/.ccache` | **按 OpenWrt 平台** 共享 | 如多个 filogic 机型共用一份编译缓存 |
| `CONFIG_CCACHE=y` | 编译器级别 | 配合 `ccache` 包与 PATH |

平台 slug 在 `build.yml` 中从设备 `.config` 解析（如 `mediatek-filogic`、`ramips-mt7621`）。

## 环境变量（workflow 内）

- `CCACHE_MAXSIZE=10G` — 避免 2G 过小导致缓存被挤出
- `CCACHE_COMPRESS=1` — 节省 Actions 缓存体积

## 使用建议

1. **日常测试**：只编一台设备，不要频繁用 `all`（10 路并行会抢缓存、变慢）。
2. **第二次编同平台**：例如先编 `redmi-ax6000`，再编 `xiaomi-ax6000`，ccache 命中率更高。
3. **大改配置后**：修改 `configs/custom-plugins.config` 或 `setup-custom-packages.sh` 会刷新 cache key，首次仍较慢属正常。
4. **更快方案（需自备）**：自托管 Runner + 持久磁盘保留 `dl/`、`build_dir/`、`~/.ccache`。

## ImageBuilder 快速路径

`build-immortalwrt-fast.yml` 使用官方 [ImageBuilder](https://downloads.immortalwrt.org/) + 全量编译缓存的自定义 `ipk`，单台约 3～8 分钟。

**流程：**

1. 先运行 **Build ImmortalWrt**（全量）→ 收集真实架构目录下的 ipk，写入缓存并上传 `immortalwrt-ipk-<arch>` 构件
2. 再运行 **Build ImmortalWrt (Fast)** → 恢复缓存；若无缓存则从最近一次全量构建下载 ipk

单台快速构建前，需至少对该**架构**跑过一次全量（如 `phicomm-k2p` 需 `mips_24kc` 的 ipk）。插件大改后需重新全量编译。
