# CI 说明

全量编译 job 在 `ubuntu-22.04` runner 上运行，依赖由 `.github/ci/install-build-deps.sh` 安装；`dl` / `feeds` / `ccache` 仍走 Actions cache。

CI 逻辑在 `.github/workflows/` 与 `.github/ci/`；`scripts/` 仅保留自定义固件内容（feeds/插件/overlay）。

## Feeds（LEDE）

**不要**覆盖 `feeds.conf.default`。LEDE 使用 `coolsnowwolf/packages`、`coolsnowwolf/luci` 等；`setup-custom-packages.sh` 仅 **追加** PassWall 两条 feed。

## Go 包版本（golang/host ~1.21）

| 包 | 上游默认 | 构建固定 |
|----|----------|----------|
| xray-core | 26.x (Go 1.26+) | 24.12.31 |
| sing-box | 1.13.x (Go 1.24+) | 1.11.0 |

由 `setup-custom-packages.sh` 内 `patch_feeds()` 写入，末尾 `verify_setup()` 校验。

## Kconfig 循环依赖

禁止 `feeds install -p kenzo|small` 全量安装。`common.config` 已禁用 `luci-app-unblockneteasemusic` 等冲突包。

## 构建脚本链

1. `setup-custom-packages.sh`（feeds + patch + 自定义包克隆 + 校验）
2. workflow 内联合并 `.config`，内联 base `defconfig` + TurboACC 启用
3. workflow 内联编译（失败会 `exit 1`，并行失败会 `-j1 V=s` 重试）
4. `pack-firmware.sh`（无镜像则失败）

## libselinux / pcre2

已禁用 `libselinux`/`libsepol`（路由器不需要 SELinux，且易在 `pcre2.h` 未进 staging 时编译失败）。`common.config` 中保留 `pcre2` + `libpcre2` 供 PassWall 等使用。

## 不编译的包（避免 rust/gn）

`shadowsocks-rust`、`naiveproxy` 会拉取 `rust`/`gn` host 编译，已在 `common.config` 关闭，并由 `configs/snippets/no-rust-passwall.config` 兜底。

## TurboACC

已关闭 `INCLUDE_OFFLOADING`（`kmod-fast-classifier` / shortcut-fe 仅部分平台存在）。保留 BBR + nft-fullcone。

**不要**在 `device.config` / `common.config` / `custom-plugins.config` 里启用 TurboACC。`luci-app-turboacc` 使用 `scripts/overlays/luci-app-turboacc/Makefile`（**无** `LUCI_DEPENDS → kmod-*`，避免 Kconfig 环）；`kmod-tcp-bbr` / `kmod-nft-fullcone` 仅在 `configs/snippets/turboacc.config` 里启用。每次 `make defconfig/oldconfig` 前运行 `.github/ci/patch-kconfig-tree.sh` 删除 `nftables-json` 重复包并重新打补丁。

## 生成 .config（workflow 内联）

合并顺序（与用户预期一致）：

1. `configs/<repo>/<device>.config` — TARGET + 机型 WiFi/驱动  
2. `configs/<repo>/common.config` — PassWall、LuCI、公共库  
3. `configs/custom-plugins.config` — MosDNS、TurboACC 等  

然后由 workflow 内联的 sanitize 逻辑删除会触发 **Kconfig 环** 的行，再 `make defconfig`。

**禁止写入合并 .config 的项：**

| 禁止 | 原因 |
|------|------|
| `CONFIG_PACKAGE_dnsmasq-full=y` / `dnsmasq_full_*` | 与 `dnsmasq_full_nftset` 递归依赖 |
| `CONFIG_PACKAGE_luci-app-turboacc*`（合并阶段） | 仅 workflow 的 TurboACC 启用步骤后写入 |
| `CONFIG_PACKAGE_kmod-nft-fullcone=y`（合并阶段） | 同上，避免与 feeds 重复包形成环 |

dnsmasq 使用 target 自带的 **DEFAULT_PACKAGES**（`dnsmasq`），不强行选 `dnsmasq-full`。

**一次性 Kconfig 修复（`build.yml` 内联）：**

1. 从 `feeds.conf*` 删除 kenzo/small，并 `rm -rf feeds/{kenzo,small}`
2. 按 `PKG_NAME:=nftables-json` 删除重复包（修复自引用环）
3. dnsmasq 去掉 nftset→nftables-json；**nftables** 用户态 Makefile 去掉 `+kmod-nft-fullcone` 并禁用 `nftables-json` 变体（LEDE 上游与自定义 `package/nft-fullcone` 会形成 Kconfig 环）；删除 feeds 里重复的 `kmod-nft-fullcone`（保留 `package/nft-fullcone`）
4. TurboACC：**clone `luci-app-turboacc` + `nft-fullcone`**；workflow 在 base `make defconfig` 前暂存 TurboACC 包，defconfig 后恢复并启用。
5. workflow 内联 sanitize — `.config` 守卫项（dnsmasq / nftables / 合并阶段 TurboACC）
6. `patch_feeds()` **不得**删除 `feeds/luci/luci-ssl`；仅清理 kenzo/small 里的重复 `luci-ssl`
7. Actions cache key：`feeds-*-kconfig-fix-v6-*` / `dl-*-kconfig-fix-v6-*`
8. workflow：cache 恢复后、setup 后都执行内联 scrub

workflow 内联 defconfig 校验：日志里出现任意 `recursive dependency detected` 即失败（不再 WARN 放过）。

## LuCI 简体中文

| 包 | 说明 |
|----|------|
| `luci-i18n-base-zh-cn` / `firewall` | `common.config` |
| `luci-i18n-passwall-zh-cn` | PassWall 界面 |
| `luci-i18n-mosdns-zh-cn` | `custom-plugins.config` |
| `luci-i18n-ttyd-zh-cn` / `arpbind` / `opkg` | `snippets/luci-zh-cn.config` |

首次启动 `files/etc/uci-defaults/96-luci-zh-cn` 设置 `luci.main.lang=zh_cn`。TurboACC 无独立 i18n 包，菜单文案随 base 中文。

## 缓存

`feeds-*-kconfig-fix-v6-*` / `dl-*-kconfig-fix-v6-*`：Kconfig 修复或 setup 逻辑变更时递增版本，避免旧 feeds 树（含 kenzo/small、重复 nftables-json）被复用。

## CONFIG_PACKAGE 解析

`setup-custom-packages.sh` 内联 `extract_kconfig_packages()`，**排除** `*_INCLUDE_*` / `*_Including_*`；安装后执行 `patch_feeds()`。

## setup 校验

`verify_setup()`：PassWall + xray/sing-box 版本 + `luci-ssl` + MosDNS / TurboACC / Aurora / arpbind / `nft-fullcone`
- workflow setup 校验：禁止在 device/common/custom 中提前写 TurboACC / dnsmasq-full / nftables-json
- 克隆失败立即 `exit 1`（不再静默继续）

## matrix / GITHUB_OUTPUT

workflow setup 步骤直接写 `repo=`、`upstream=`、`matrix=` 到 `GITHUB_OUTPUT`，并在同一步执行配置校验。

## 设备 WiFi / 核心包

- 全设备合并 `configs/snippets/wireless-core.config`（`iw`、`wireless-regdb`、`cfg80211`、`mac80211`）。
- **LEDE K2P**：`kmod-mt7615d` + `kmod-mt7615d_dbdc` + `maccalc` + `wireless-tools`（lean 闭源驱动）。
- **ImmortalWrt K2P**：`kmod-mt7615e` + `kmod-mt7615-firmware`（主线 mt76，**不要** `mt7615d_dbdc`）。
- **ImmortalWrt filogic**（WR30U / AX6000）：target 须为 `*-stock`；驱动包含 `kmod-mt7915e` + 对应 `*-firmware` / `*-wo-firmware`。
- **ImmortalWrt CR660x**：target 为 `cr6606`（非 `cr660x` 聚合名）。
- setup 预装 feeds：`maccalc`、`wireless-regdb`、`iw`、`kmod-mt7615-firmware`、`kmod-mt7915-firmware`。
- workflow setup 阶段按平台校验上述规则。

## 常见 Makefile WARNING（多数可忽略）

| 包 | 用途 | 是否要管 |
|----|------|----------|
| `lldpd` → `libnetsnmp` | 二层邻居发现（LLDP），可选 SNMP 扩展 | **否**，与 WiFi 无关；未选 `lldpd` 时仅 metadata 扫描告警 |
| `mt7615d` → `maccalc` | 斐讯 K2P 等 **MT7615 DBDC** 闭源 WiFi 驱动的 MAC 计算工具 | **是**（仅 `phicomm-k2p` 等启用 `kmod-mt7615d_dbdc` 时） |

`maccalc` 在官方 `packages` feed 的 `net/maccalc`，setup 会 `feeds install maccalc`；设备 config 里 `CONFIG_PACKAGE_maccalc=y` 保证进固件。

## Actions Node 警告

在 GitHub **Settings → Actions → Variables** 删除 `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` 与 `ACTIONS_ALLOW_USE_UNSECURE_NODE_VERSION`（非本仓库 workflow 定义）。
