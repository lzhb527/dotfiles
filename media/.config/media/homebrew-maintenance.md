# Homebrew 维护文档（macOS 27 / Apple Silicon）

## 1. 环境

| 项 | 值 |
|---|---|
| macOS | 27.0（arm64，代号 **Golden Gate**） |
| Homebrew | 7.0.6，前缀 `/opt/homebrew` |
| brew 源 | `https://mirrors.ustc.edu.cn/brew.git` |
| API 源 | `https://mirrors.ustc.edu.cn/homebrew-bottles/api` |
| bottle 源 | **官方 `ghcr.io`（不使用镜像）** |

## 2. 核心结论：bottle 必须走官方源

**现象**：`brew install/reinstall/upgrade` 报

```
Error: Couldn't find manifest matching bottle checksum.
```

**根因**：macOS 27 使用 `arm64_golden_gate` 这个 bottle 标签。USTC / NJU 的 **bottle OCI manifest 镜像同步滞后**，缺少 `arm64_golden_gate` 条目，而它们的 API JSON 已更新——校验和对不上。

**实测结论**：

- USTC manifest：停留 2026-09-05，缺 golden_gate ❌
- NJU（`ghcr.nju.edu.cn`）：`pkgconf` 有、`hello` 等却缺 golden_gate ❌（且 Homebrew 只认 `ghcr.io`，自定义域名会走 legacy 路径）
- 官方 `ghcr.io`：manifest 最新、可正常下载 ✅

**配置**（`~/.config/fish/config.fish`）：

```fish
set -gx HOMEBREW_NO_AUTO_UPDATE 1
set -gx HOMEBREW_API_DOMAIN "https://mirrors.ustc.edu.cn/homebrew-bottles/api"
set -gx HOMEBREW_BREW_GIT_REMOTE "https://mirrors.ustc.edu.cn/brew.git"
set -gx HOMEBREW_CORE_GIT_REMOTE "https://mirrors.ustc.edu.cn/homebrew-core.git"
# 注意: 不要设 HOMEBREW_BOTTLE_DOMAIN, 让其走官方 ghcr.io
```

> 关键：**API 可用国内镜像（已同步），bottle 必须走官方**。当前 shell 若仍导出旧的 `HOMEBREW_BOTTLE_DOMAIN`，先 `set -e HOMEBREW_BOTTLE_DOMAIN` 或开新终端。

## 3. 已完成的清理（`brew doctor` 归零）

| 类别 | 处理 |
|---|---|
| pkgconf 平台不符 | `brew reinstall pkgconf`（3.0.6 → 3.0.7） |
| 无 formula 的 keg | `exa`、`openssl@1.1` 卸载；zathura 三件套升级刷新 tap 记录 |
| 废弃 formula | 卸载 `exa openssl@1.1 antigen espeak pcre speedtest-cli`（先重装 `ag` 切 pcre2） |
| 废弃 tap | `brew untap homebrew/services asmvik/formulae mopidy/mopidy nikitabobko/tap` |
| 未信任 tap | `brew trust --formula bjarneo/cliamp/cliamp` |
| 缺失依赖 | 安装 zathura 的 10 个依赖，`brew missing` 已空 |
| zathura 旧 tap | 记录已指向 `homebrew-zathura/zathura` |

**保留不动**：`/usr/local/lib` 下 root 所有的银行 U 盾驱动（`HBCMBC`、`cmbc_*`、`libFTCMBC`、`libEsCcbSlotApi`）与 2019 年手工编译的 `espeak`/`portaudio`。这些 doctor 警告可忽略。

## 4. zathura PDF 插件

zathura 二进制写死的插件目录：`/opt/homebrew/Cellar/zathura/<版本>/lib/zathura`。

```fish
mkdir -p /opt/homebrew/opt/zathura/lib/zathura
ln -sf /opt/homebrew/opt/zathura-pdf-mupdf/libpdf-mupdf.dylib /opt/homebrew/opt/zathura/lib/zathura/
```

- 只链 **一个** PDF 后端（mupdf 与 poppler 都注册 `com.adobe.pdf`，同时链会报错）
- ⚠️ 目录在版本化 Cellar 内，**每次 `brew upgrade zathura` 后需重新链接**

## 5. 升级后清理旧包

```fish
brew upgrade                 # 升级(自动清理本次产生的旧版本)
brew cleanup                 # 清理历史遗留旧 keg
brew cleanup --prune=all     # 清空下载缓存
brew autoremove              # 删除孤儿依赖
brew doctor                  # 验证
```

| 命令 | 作用 | 备注 |
|---|---|---|
| `brew cleanup -n` | 预演 | 显示将删项与可回收空间 |
| `brew cleanup` | 删旧版本 keg、过期缓存、旧 cask | 升级后**自动执行**，但不清历史遗留 |
| `brew cleanup --prune=all` | 删**全部**下载缓存 | 回收最多 |
| `brew cleanup --prune=all -s` | 再 scrub | 更彻底 |
| `brew autoremove` | 删无依赖的包 | 建议先 `-n` |

**当前状态**：Cellar 8.7GB（81 个多版本旧 keg，cleanup 可释放约 1.9GB）；下载缓存 1.7GB；`autoremove` 无孤儿。合计约 **3.6GB** 可回收。

## 6. 日常维护备忘

1. 升级前确保新终端（无旧 `HOMEBREW_BOTTLE_DOMAIN`）。
2. 每次 `brew upgrade` 后跑一次 `brew cleanup`。
3. 大体积包留意：`proj`（~763MB）、`mysql`（~82MB）、`opencv`（~52MB）。
4. `mysql` 是运行中的服务（`~/Library/LaunchAgents/homebrew.mxcl.mysql.plist`），升级后如需 `brew services restart mysql`。
5. 跨大版本升级留意：`cliamp 1.x→2.x`、`graphviz 15→16`、`libnfs 7→8` 等。
