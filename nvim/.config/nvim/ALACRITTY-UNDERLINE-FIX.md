# Alacritty 下划线颜色不生效的修复（Neovim CursorLine 松石蓝下划线）

## 问题现象
Neovim 中设置了 `CursorLine` 下划线 + `sp = "#00ffff"`，但下划线颜色不显示（只有默认颜色）。

## 根本原因
Neovim 只有检测到终端支持「扩展下划线」时，才会发送下划线颜色序列（`sp`/`guisp`）。
检测依赖 terminfo 的 `Smulx` 能力，或终端应答 DECRQSS 探测。

- Alacritty 从不应答 DECRQSS（源码中无任何 DCS 处理）
- `TERM=xterm-256color` 的 terminfo 没有 `Smulx`
- 两条路都不通 → 颜色被静默丢弃，只渲染默认色下划线

实测对比（抓取 Neovim 实际发出的字节）：

| 环境 | 下划线 | 松石蓝 `\x1b[58:2::0:255:255m` |
|---|---|---|
| `TERM=xterm-256color` | ✅ | ❌ |
| `TERM=alacritty` + 正确 terminfo | ✅ | ✅ |

## 修复步骤

### 步骤 1：安装 Alacritty 的 terminfo（含 `Smulx`）

方法 A（homebrew cask 已自动安装，无需操作）：
```bash
infocmp -a alacritty | grep Smulx   # 有输出即已装好
```

方法 B（手动安装）：
```bash
curl -LO https://raw.githubusercontent.com/alacritty/alacritty/v0.17.0/extra/alacritty.info
tic -x alacritty.info               # 写入 ~/.terminfo
```

### 步骤 2：让 Alacritty 会话使用 TERM=alacritty

fish（~/.config/fish/config.fish 顶部）：
```fish
if set -q ALACRITTY_WINDOW_ID
    if infocmp alacritty >/dev/null 2>&1
        set -gx TERM alacritty
    end
end
```

zsh（~/.zshrc）：
```zsh
[[ -n "$ALACRITTY_WINDOW_ID" ]] && export TERM=alacritty
```

bash（~/.bashrc）：
```bash
[ -n "$ALACRITTY_WINDOW_ID" ] && export TERM=alacritty
```

### 步骤 3：验证
```bash
echo $TERM   # 应输出 alacritty
```

## 备注
- 本机（2026-08）已应用修复：terminfo 已装入 `~/.terminfo`，TERM 已写入 `config.fish`
- 注意：本会话内 `ssh` 到无 alacritty terminfo 的远端时，可临时 `export TERM=xterm-256color`
