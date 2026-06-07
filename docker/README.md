# Builder Docker image

预装 OpenWrt/LEDE 编译依赖的 Ubuntu 22.04 镜像，供 GitHub Actions `container:` 使用，省去每次 `apt install`（约 2～5 分钟）。

**不包含** `dl/`、`feeds/`、`ccache/`、源码树——这些仍由 Actions cache 管理。

## 镜像地址

```
ghcr.io/<owner>/<repo>/builder:22.04   # GHCR 要求全小写，如 jas0n0ss/openwrt-image-ci
ghcr.io/<owner>/<repo>/builder:latest
```

## 首次使用

1. 推送 `docker/` 后自动触发 **Build builder Docker image**，或手动 Run 该 workflow
2. 等待镜像发布到 GHCR（仓库 **Packages** 页可见）
3. 再跑 **Build LEDE** / **Build ImmortalWrt**

## 本地调试

```bash
docker build -t openwrt-builder:22.04 docker/
docker run --rm -it -v "$PWD:/workspace" openwrt-builder:22.04 bash
```
