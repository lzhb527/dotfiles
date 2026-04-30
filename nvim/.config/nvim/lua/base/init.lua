local vim = vim
local api = vim.api
local opt = vim.opt

-- 基础设置
opt.compatible = false               -- 禁用 vi 兼容模式
opt.termguicolors = true             -- 启用真彩色
opt.encoding = "utf-8"               -- 编码设置
opt.fileencodings = "utf-8,gbk,ucs-bom"
opt.fileformat = "unix"              -- 使用 Unix 换行符

-- 显示设置
opt.number = true                    -- 显示行号
opt.relativenumber = true            -- 显示相对行号
opt.cursorline = true                -- 高亮当前行
opt.mouse = "a"                      -- 启用鼠标支持
opt.guifont = "DroidSansMono_Nerd_Font:h11"  -- GUI 字体设置

-- 折叠设置
opt.foldmethod = "indent"            -- 基于缩进折叠
opt.foldlevel = 99                   -- 默认不折叠
opt.foldenable = true                -- 启用折叠

-- 窗口设置
opt.splitbelow = true                -- 水平分割时下置新窗口
opt.splitright = true                -- 垂直分割时右置新窗口

-- 缩进设置 (全局默认，Python 单独在 autocmd 中覆盖)
opt.tabstop = 4                      -- 制表符宽度
opt.softtabstop = 4                  -- 软制表符宽度
opt.shiftwidth = 4                   -- 自动缩进宽度
opt.expandtab = true                 -- 制表符转为空格
opt.autoindent = true                -- 自动缩进
opt.smartindent = true               -- 智能缩进

-- 搜索设置
opt.hlsearch = true                  -- 高亮搜索结果
opt.incsearch = true                 -- 增量搜索
opt.ignorecase = true                -- 忽略大小写
opt.smartcase = true                 -- 智能大小写匹配

-- 滚动设置
opt.scrolloff = 5                    -- 上下滚动边距
opt.sidescrolloff = 5                -- 左右滚动边距

-- 性能优化
opt.lazyredraw = true                -- 延迟重绘
opt.updatetime = 200                 -- 更新时间间隔
opt.timeoutlen = 500                 -- 按键超时时间

-- 文件处理
opt.backup = false                   -- 禁用备份文件
opt.swapfile = false                 -- 禁用交换文件
opt.writebackup = false              -- 禁用写入备份
opt.undofile = true                  -- 启用撤销文件
opt.undodir = vim.fn.expand("~/.config/nvim/undo//")  -- 撤销文件目录

-- 按键设置
vim.g.mapleader = "\\"               -- Leader 键设置为反斜杠

-- 全局透明背景（基础）
opt.background = "dark"
opt.winblend = 10 -- 全局窗口透明度（0-100）
opt.pumblend = 10 -- 补全菜单透明度
