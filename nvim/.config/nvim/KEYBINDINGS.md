# Neovim 快捷键速查表

> Leader 键为 `空格`（`<Space>`）。`<leader>x` 即按空格后按 x。
> 模式：`n` 普通 / `i` 插入 / `v` 可视 / `t` 终端 / `x`+`o` 可视与操作符待决

---

## 一、基础 / 文件

| 按键 | 模式 | 功能 |
|---|---|---|
| `<C-s>` | n/i/v | 快速保存 |
| `<C-n>` | n | 文件浏览器开关（snacks.explorer 侧边栏） |
| `<F1>` | n | 切换行号显示（nu/rnu） |
| `<F6>` / `<leader>fm` | n | 智能异步格式化（conform → LSP 兜底） |
| `<F12>` / `<leader>uf12` | n | 代码结构树开关（aerial） |
| `<leader>e` / `<leader>un` | n | 侧边文件树开关（snacks.explorer） |
| `-` | n | 打开 Oil 目录编辑器 |
| `<leader>oc` | n | 编辑 Neovim 主配置 |
| `<leader>ou` | n | 一键更新所有插件（Lazy） |
| `<leader>oq` | n | 安全退出 Neovim |
| `<leader>?` | n | Which-Key 快捷键帮助 |

## 二、文件存取

| 按键 | 模式 | 功能 |
|---|---|---|
| `<leader>ss` | n | 保存当前文件 |
| `<leader>sS` | n | 强制保存 |
| `<leader>sw` | n | 另存为… |
| `<leader>sa` | n | 保存所有打开文件 |
| `<leader>sq` | n | 退出当前窗口 |
| `<leader>sc` | n | 临时草稿缓冲（snacks.scratch） |

## 三、标签页 / 缓冲区（bufferline）

| 按键 | 模式 | 功能 |
|---|---|---|
| `<C-Tab>` / `<leader>bn` | n | 下一个标签 |
| `<C-S-Tab>` / `<leader>bp` | n | 上一个标签 |
| `<leader>bd` | n | 强制关闭当前标签 |

## 四、窗口分屏

| 按键 | 模式 | 功能 |
|---|---|---|
| `<leader>wv` | n | 垂直分屏 |
| `<leader>wh` | n | 水平分屏 |
| `<leader>wc` | n | 关闭当前窗口 |
| `<leader>wo` | n | 最大化当前窗口 |

## 五、终端（snacks.terminal）

| 按键 | 模式 | 功能 |
|---|---|---|
| `<F2>` | n/t | 切换浮动终端（t 模式=收起） |
| `<F9>` | n/t | 切换底部终端（t 模式=收起） |
| `<F10>` | n | 关闭当前终端窗口 |
| `<Esc><Esc>` | t | 双击 Esc 退出终端输入模式 |
| `<leader>tn` | n/t | 新建浮动终端（t 模式=收起） |
| `<leader>th` | n | 新建底部终端 |
| `<leader>tk` | n | 关闭当前终端窗口 |
| `q` | t(正常模式) | 隐藏当前终端（snacks 内置） |

## 六、搜索（snacks.picker）

| 按键 | 模式 | 功能 |
|---|---|---|
| `<leader>ff` | n | 查找文件 |
| `<leader>fg` | n | 全局文本搜索（grep） |
| `<leader>fb` | n | 查找活动缓冲区 |
| `<leader>fh` | n | 历史打开记录 |
| `<leader>fc` | n | Git 提交历史 |
| `<leader>fr` | n | 搜索光标下单词 |

## 七、LSP 代码行为

| 按键 | 模式 | 功能 |
|---|---|---|
| `K` | n | 悬浮文档（hover） |
| `gd` / `<leader>cd` | n | 跳转至定义 |
| `gi` / `<leader>ci` | n | 跳转至接口实现 |
| `gr` / `<leader>cf` | n | 查找全局引用 |
| `<leader>r` / `<leader>cr` | n | 重命名变量/符号 |
| `<leader>ce` | n | 弹窗查看诊断信息 |
| `<leader>ck` | n | 查看悬浮文档 |
| `<leader>cs` | n | LSP 代码符号列表（Trouble） |
| `<leader>cl` | n | LSP 定义/引用树（Trouble） |

## 八、诊断跳转

| 按键 | 模式 | 功能 |
|---|---|---|
| `[d` / `]d` | n | 上一个/下一个诊断 |
| `[e` / `]e` | n | 上一个/下一个错误 |
| `<leader>cp` | n | 上一个诊断 |
| `<leader>cn` | n | 下一个诊断 |

## 九、诊断看板（Trouble / Loclist）

| 按键 | 模式 | 功能 |
|---|---|---|
| `<leader>as` | n | 打开错误位置列表（setloclist） |
| `<leader>ad` | n | 浮窗查看错误 |
| `<leader>ap` | n | 上一个错误 |
| `<leader>an` | n | 下一个错误 |
| `<leader>ax` | n | 项目全局错误看板 |
| `<leader>aX` | n | 当前文件错误看板 |
| `<leader>aq` | n | Quickfix 增强列表 |
| `<leader>al` | n | Loclist 位置列表 |

## 十、Git

| 按键 | 模式 | 功能 |
|---|---|---|
| `<leader>gs` | n | 开关左侧状态线 |
| `<leader>gg` | n | LazyGit 全功能 TUI |
| `<leader>gL` | n | LazyGit 提交日志 |
| `<leader>gF` | n | LazyGit 当前文件日志 |
| `]c` / `<leader>gj` / `<leader>gk` | n | 下一个/上一个改动块 |
| `<leader>gl` | n | 预览当前行改动（Inline） |
| `<leader>gP` / `<leader>hp` | n | 弹窗预览当前修改块 |
| `<leader>ga` / `<leader>hs` | n | 暂存当前修改块 |
| `<leader>gr` / `<leader>hr` | n | 撤销当前修改块 |
| `<leader>gb` / `<leader>hb` | n | 当前行完整 Blame |
| `<leader>gd` / `<leader>hd` | n | 对比当前文件与 Git 差异 |

## 十一、代码调试（DAP）

| 按键 | 模式 | 功能 |
|---|---|---|
| `<F5>` | n | 启动/继续调试 |
| `<F3>` | n | 切换断点 |
| `<leader>db` | n | 断点开关 |
| `<leader>dB` | n | 条件断点 |
| `<leader>dc` | n | 启动/继续调试 |
| `<leader>ds` | n | 选择调试配置（含 attach） |
| `<leader>di` | n | 步入（Step Into） |
| `<leader>do` | n | 步过（Step Over） |
| `<leader>du` | n | 步出（Step Out） |
| `<leader>da` | n | 调试当前文件（带参数） |
| `<leader>dr` | n | REPL 控制台开关 |
| `<leader>dt` | n | 调试 UI 开关 |
| `<leader>dl` | n | 查看调试终端输出 |
| `<leader>de` | n | 评估变量/表达式 |
| `<leader>dR` | n | 重启调试会话 |
| `<leader>dQ` | n | 终止调试会话 |

## 十二、跳转 / 文本对象

| 按键 | 模式 | 功能 |
|---|---|---|
| `s` | n/x/o | Flash 极速跳转 |
| `S` | n/x/o | Flash 选中 Treesitter 代码块 |
| `<leader>us` | n | Flash 局部闪现跳转 |
| `]m` / `[m` | n/x/o | 下一个/上一个函数 |
| `]C` / `[C` | n/x/o | 下一个/上一个类 |
| `]a` / `[a` | n/x/o | 下一个/上一个参数 |
| `]f` / `[f` | n/x/o | 下一个/上一个函数调用 |
| `ys`/`cs`/`ds` | n | 加/改/删包围符号（nvim-surround） |
| `di(` / `ciw` / `vit` 等 | n | 文本对象增强（mini.ai） |

## 十三、补全（blink.cmp，插入模式内）

| 按键 | 模式 | 功能 |
|---|---|---|
| `<Tab>` | i | 选择下一个 / snippet 前进 |
| `<S-Tab>` | i | 选择上一个 / snippet 后退 |
| `<CR>` | i | 确认补全 |
| `<Esc>` | i | 收起补全菜单 |
| `<C-Space>` | i | 手动呼出补全 |

## 十四、其它插件

| 按键 | 模式 | 功能 |
|---|---|---|
| `<F7>` | n | 撤销树（undotree） |
| `<leader>ft` | n | 查看 TODO/FIXME（TodoQuickFix） |
| `<leader>v` | n | 切换 Python 虚拟环境（venv-selector） |
| `<leader>qs` | n | 保存会话（persistence） |
| `<leader>ql` | n | 恢复会话 |
| `<leader>qd` | n | 停止自动保存会话 |

## 十五、启动页 Dashboard（snacks）

| 按键 | 功能 |
|---|---|
| `f` | 查找文件 |
| `n` | 新建文件 |
| `g` | 全局文本搜索 |
| `r` | 最近文件 |
| `c` | 打开配置文件 |
| `s` | 恢复会话 |
| `l` | Lazy 插件管理 |
| `q` | 退出 |

## 十六、文件树内快捷键（snacks.explorer）

| 按键 | 功能 |
|---|---|
| `r` | 重命名当前文件/文件夹（自动同步引用） |
| `m` | 单个=改名；多选后=移动到当前目录 |
| `c` | 单个=复制命名；多选后=复制到当前目录 |
| `y` | 复制所选文件路径（配合 `p` 粘贴） |
| `p` | 粘贴（跨实例） |
| `a` | 新建文件（以 `/` 结尾为目录） |
| `d` | 删除（优先回收站） |
| `u` | 刷新目录树 |
| `<CR>`/`l` | 打开文件 / 展开目录 |
| `h` | 收起目录 |
| `<BS>` | 返回上一级目录 |
| `.` | 聚焦当前目录 |
| `H` | 切换隐藏文件显示 |
| `I` | 切换 gitignore 忽略文件显示 |
| `<leader>/` | 在当前目录 grep |
| `<C-t>` | 在当前目录打开终端 |

