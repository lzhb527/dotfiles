# Neovim 配置

> 性能优化版 · 43 个插件
>
> 快捷键总览见 [KEYBINDINGS.md](./KEYBINDINGS.md)

---

## 📁 目录结构

```
~/.config/nvim/
├── init.lua                        # 唯一的核心总入口
├── lazy-lock.json                  # 插件锁版本文件（自动生成）
├── README.md                       # 本文件
├── KEYBINDINGS.md                  # 快捷键速查表
├── .aiderignore                    # Aider 忽略 undo/ 等目录
└── lua/
    ├── configs/                    # 编辑器自身的“基础行为”配置
    │   ├── base.lua                # 行号/缩进/折叠/诊断/平滑滚动
    │   ├── keymaps.lua             # 全局快捷键 + which-key 菜单
    │   ├── filetype.lua            # 文件头自动插入 / 光标位置恢复
    │   └── theme.lua               # catppuccin 主题 + 高亮定制
    │
    └── plugins/                    # 与“插件”相关的代码
        ├── init.lua                # 插件清单表（地址 + 加载时机）
        └── configs/                # 每个插件一个配置文件
            ├── treesitter.lua      # 解析器管理
            ├── blink.lua           # 补全 + snippets
            ├── autopairs.lua       # 括号自动补全
            ├── mason.lua           # mason + lspconfig + tool-installer
            ├── lsp.lua             # pyright / ruff / ansiblels
            ├── lint.lua            # nvim-lint（shellcheck/yamllint）
            ├── conform.lua         # 代码格式化（ruff/stylua/shfmt/prettier）
            ├── venv.lua            # Python 虚拟环境切换
            ├── oil.lua             # 目录即文本编辑 + snacks.rename 联动
            ├── flash.lua           # 极速跳转
            ├── gitsigns.lua        # Git 状态/块操作
            ├── aerial.lua          # 代码结构大纲
            ├── noice.lua           # 命令行美化
            ├── snacks.lua          # dashboard/statuscolumn/picker/terminal/indent 等
            ├── markview.lua        # Markdown 渲染增强
            ├── dap.lua             # nvim-dap 调试核心
            ├── dapui.lua           # 调试 UI
            ├── lualine.lua         # 状态栏
            ├── bufferline.lua      # 多标签顶栏
            ├── whichkey.lua        # 按键提示
            ├── trouble.lua         # 诊断看板
            ├── tiny-inline-diagnostic.lua # 光标行内诊断
            ├── rainbow.lua         # 彩虹括号
            └── colorizer.lua       # 颜色值高亮
```

---

# 🧩 插件清单（43 个）

### 主题


| 插件 | 说明 |
|---|---|
| **catppuccin** | 配色主题（mocha 暗色） |


## 语法 / 文本


| 插件 | 说明 |
|---|---|
| **nvim-treesitter** | 语法高亮 + 解析器管理 |
| **nvim-treesitter-textobjects** | 语法树结构跳转（`]m`/`]C`/`]a`/`]f`） |


## LSP / 补全 / 格式化


| 插件 | 说明 |
|---|---|
| **nvim-lspconfig** | LSP 配置（pyright / ruff / ansiblels） |
| **blink.cmp** | 补全引擎 |
| **friendly-snippets** | 代码片段库（blink 依赖） |
| **nvim-autopairs** | 括号自动补全 |
| **nvim-lint** | 外部 linter（shellcheck / yamllint） |
| **conform.nvim** | 异步格式化 |
| **mason.nvim** | 工具安装器 |
| **mason-lspconfig.nvim** | LSP 服务器安装（mason 依赖） |
| **mason-tool-installer.nvim** | 命令行工具自动安装（mason 依赖） |
| **venv-selector.nvim** | Python 虚拟环境切换 |


## 文件 / 搜索 / 导航


| 插件 | 说明 |
|---|---|
| **snacks.explorer** | 侧边栏文件树（`<C-n>` / `<leader>e` / `<leader>un`） |
| **oil.nvim** | 目录即文本编辑（批量重命名 + 引用同步） |
| **snacks.picker** | 搜索（替代 telescope） |
| **flash.nvim** | 极速跳转 |


## Git


| 插件 | 说明 |
|---|---|
| **gitsigns.nvim** | Git 状态符号 / 块操作 / Blame |
| **snacks.lazygit** | Git 全功能 TUI（含 diff 查看） |


## 编辑增强


| 插件 | 说明 |
|---|---|
| **nvim-surround** | `ys`/`cs`/`ds` 包围符操作 |
| **mini.ai** | 文本对象增强 |
| **todo-comments.nvim** | TODO/FIXME 高亮 + 看板 |
| **undotree** | 可视化撤销树 |
| **vim-illuminate** | 光标词出现高亮（无 LSP 兜底） |
| **markview.nvim** | Markdown 渲染增强 |
| **rainbow-delimiters.nvim** | 彩虹括号 |
| **nvim-colorizer.lua** | 颜色值高亮 |
| **snacks.indent** | 缩进线 + 当前作用域高亮 |


## UI


| 插件 | 说明 |
|---|---|
| **snacks.nvim** | dashboard / statuscolumn / terminal / indent / bufdelete / words 等 |
| **lualine.nvim** | 状态栏 |
| **bufferline.nvim** | 多标签顶栏 |
| **which-key.nvim** | 按键提示 |
| **noice.nvim** | 命令行 / 消息美化 |
| **snacks.terminal** | 浮动 / 底部终端（`F2` 浮动 / `F9` 底部 / `F10` 关闭） |
| **aerial.nvim** | 代码大纲侧边栏 |


## 诊断


| 插件 | 说明 |
|---|---|
| **trouble.nvim** | 诊断看板 |
| **tiny-inline-diagnostic.nvim** | 光标行内诊断 |


## 调试（DAP）


| 插件 | 说明 |
|---|---|
| **nvim-dap** | 调试引擎 |
| **nvim-dap-ui** | 调试 UI（变量 / 断点 / 调用栈） |
| **nvim-dap-virtual-text** | 调试行内变量显示 |
| **mason-nvim-dap.nvim** | 调试器自动安装（debugpy / codelldb） |


## 会话


| 插件 | 说明 |
|---|---|
| **persistence.nvim** | 会话保存 / 恢复 |


## 依赖（他插件引用，不可删）

`lazy.nvim` / `plenary.nvim` / `nvim-web-devicons` / `nui.nvim` / `nvim-nio` / `nvim-notify`

---

## 🚀 新机器安装清单

## 1. 系统工具
Xcode CLT（treesitter 编译解析器必需）：

```bash
xcode-select --install
```

## 2. brew 安装

```bash
brew install neovim ripgrep fd tree-sitter shellcheck yamllint tte lazygit ansible
```

| 工具 | 用途 |
|---|---|
| `neovim` | Neovim ≥ 0.12（用了 0.12 特性） |
| `ripgrep` | snacks.picker 的 grep 搜索依赖 |
| `fd` | snacks.picker 找文件更快（推荐） |
| `tree-sitter` | 编译解析器 |
| `shellcheck` | sh 脚本 lint（nvim-lint） |
| `yamllint` | yaml / ansible lint（nvim-lint） |
| `tte` | dashboard 动画 Logo（terminaltexteffects） |
| `lazygit` | Git 可视化界面 |
| `ansible` | ansiblels LSP 使用（也可 pip 装） |

## 3. Nerd Font

- [ ] 安装 `DroidSansMono Nerd Font`（dashboard 图标 / 头图字形）

## 4. python3

pyright / debugpy 用（平时可用 venv）：

```bash
python3 -m ensurepip
```

## 5. 拷贝配置并首启

```bash
cp -r ~/.config/nvim <新机器>/.config/nvim
nvim   # 首次启动 Mason 会自动装齐 pyright/ruff/ansiblels/debugpy/stylua/shfmt/prettier 等
```

---

## 💡 说明

- `fzf` 不需要（已用 snacks.picker）
- `telescope-fzf-native` 已移除
- 完整快捷键见 [KEYBINDINGS.md](./KEYBINDINGS.md)
