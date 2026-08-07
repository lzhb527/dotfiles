-- 1. Lazy.nvim 安装
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- 2. 核心全局行为设置（确保一些现代化插件正常工作）
vim.g.mapleader = " " -- 设置空格键为 Leader 键
vim.opt.termguicolors = true -- 开启 24 位真彩色支持

-- 3. 插件配置列表
require("lazy").setup({
	-- =========================================================================
	-- 3.1 配色主题
	-- =========================================================================
	{
		"UtkarshVerma/molokai.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("configs.theme") -- 甩给专门的主题文件去激活(configs/theme.lua)
		end,
	},
	{ "folke/tokyonight.nvim", lazy = false, priority = 1000 },
	{ "catppuccin/nvim", name = "catppuccin", lazy = false, priority = 1000 },

	-- =========================================================================
	-- 3.2 现代化核心：代码高亮与语义解析引擎
	-- =========================================================================
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		dependencies = {
			"lewis6991/ts-install.nvim", -- 你的自动安装增强插件
		},
		config = function()
			-- 1. 先初始化 ts-install
			require("ts-install").setup({
				auto_install = true,
			})

			-- 2. 🚀 最新版 nvim-treesitter 的正确初始化姿势（不再使用 .configs）
			require("nvim-treesitter").setup({
				-- 基础解析器强制锁死安装
				ensure_installed = { "lua", "vim", "vimdoc", "query", "markdown" },

				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},
				indent = {
					enable = true,
				},
			})
		end,
	},

	-- =========================================================================
	-- 3.3 LSP、补全、代码检查与格式化
	-- =========================================================================
	{ "neovim/nvim-lspconfig" }, -- LSP 核心(lsp.lua.0)
	{ "hrsh7th/nvim-cmp" }, -- 补全核心(cmp.lua.2)
	{ "hrsh7th/cmp-nvim-lsp" }, -- LSP 补全源
	{ "L3MON4D3/LuaSnip" }, -- 代码片段引擎(plugins.configs.cmp.lua.1)
	{ "saadparwaiz1/cmp_luasnip" }, -- 代码片段补全源
	{ "rafamadriz/friendly-snippets" }, -- 代码片段库
	{ "hrsh7th/cmp-path" }, -- 路径补全
	{ "hrsh7th/cmp-buffer" }, -- 缓冲区补全
	{ "windwp/nvim-autopairs" }, -- 括号自动补全(cmp.lua.3)
	{
		"williamboman/mason.nvim",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim", -- 🌟 新增：全品类工具自动下载
		},
		cmd = "Mason", -- 仅在调用 :Mason 时延迟加载
		config = true, -- 自动运行 require("mason").setup()
	},
	{ "stevearc/conform.nvim" }, -- 🌟 替换掉旧的 ALE/Flake8，现代高效异步代码格式化器(tools.lua.2)
	{
		"linux-cultist/venv-selector.nvim",
		dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim" },
	}, -- Python 虚拟环境切换

	-- =========================================================================
	-- 3.4 导航与搜索（全 Lua 升级）
	-- =========================================================================
	{
		"nvim-neo-tree/neo-tree.nvim", -- 🌟 完美替代 NERDTree，异步、颜值更高(ui.lua.7)
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
	},
	{ "folke/flash.nvim", event = "VeryLazy", enabled = true }, -- 🌟 完美替代 EasyMotion，极其高效酷炫的跳转(editor.lua.2)
	{
		"nvim-telescope/telescope.nvim", -- 🌟 现代化搜索神器，完美融合 FZF(tools.lua.1)
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" }, -- FZF 原生加速
		},
	},
	{ "lewis6991/gitsigns.nvim" }, -- 🌟 替代旧的 Fugitive，提供极致的侧边栏 Git 状态和操作
	{ "stevearc/aerial.nvim" }, -- 🌟 完美替代 Tagbar，基于 LSP 的现代函数/类大纲导航(tools.lua.4)
	{
		"folke/noice.nvim", -- 命令行与搜索栏重构(ui.8)
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
	},
	-- =========================================================================
	-- 3.5 编辑增强
	-- =========================================================================
	{ "NvChad/nvim-colorizer.lua" }, -- 颜色高亮(ui.lua.4)
	{ "lukas-reineke/indent-blankline.nvim" }, -- 🌟 替换旧的 indentLine，基于 Lua 且完美适配 Treesitter（ui.lua.5)
	{ "numToStr/Comment.nvim", keys = { { "<leader>cc", mode = { "n", "x" } } }, config = true },
	{ "HiPhish/rainbow-delimiters.nvim" }, -- 🌟 替换旧的 rainbow，基于 Treesitter 的高性能彩虹括号(ui.lua.6)
	{ "akinsho/toggleterm.nvim", version = "*" }, -- 🌟 替换旧的 floaterm，功能极度强大的浮动/多终端管理(editor.lua.3)
	{ "folke/snacks.nvim" },
	{
		"chrisgrieser/nvim-origami",
		event = "VeryLazy",
		opts = {}, -- required even when using default config

		-- recommended: disable vim's auto-folding
		init = function()
			vim.opt.foldlevel = 99
			vim.opt.foldlevelstart = 99
		end,
	},
	{
		"mg979/vim-visual-multi",
		branch = "master",
		init = function()
			vim.g.VM_maps = {
				["Find Under"] = "<C-m>",
			}
		end,
	},

	-- =========================================================================
	-- 3.6 UI 增强
	-- =========================================================================
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
	}, -- 状态栏(ui.lua.1)
	{ "echasnovski/mini.icons", version = false },
	{ "nvimdev/dashboard-nvim" }, -- 启动页（已修正原仓库作者改名问题）(ui.lua.3)
	{ "karb94/neoscroll.nvim" }, -- 🌟 替换旧的 comfortable-motion.vim，平滑滚动
	{ "akinsho/bufferline.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } }, -- 缓冲区多标签页(ui.lua.2)
	{ "folke/which-key.nvim" }, -- 按键提示

	-- =========================================================================
	-- 3.7 诊断美化（在光标当前行优雅显示报错详情）
	-- =========================================================================
	{
		"folke/trouble.nvim",
		opts = {}, -- 必须留空或传表以触发初始化
		cmd = "Trouble", -- 懒加载：只有在调用 Trouble 命令时才加载
	},
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = "LspAttach", -- 当 LSP 启动时再懒加载
		priority = 1000, -- 保证优先级
		config = function()
			require("tiny-inline-diagnostic").setup({
				-- 插件本身的个性化配置可以写在这里，默认就非常好看
				signs = {
					left = "▍",
					right = " ",
				},
			})
		end,
	},
}, {
	-- Lazy 的全局 UI 配置
	ui = { border = "rounded" },
	performance = {
		rtp = {
			disabled_plugins = {
				"netrw",
				"netrwPlugin",
				"netrwSettings",
				"netrwFileHandlers",
				"gzip",
				"zip",
				"zipPlugin",
				"tar",
				"tarPlugin",
				"getscript",
				"getscriptPlugin",
				"vimball",
				"vimballPlugin",
				"2html_plugin",
				"logiPat",
				"rrhelper",
				"spellfile_plugin",
				"matchit",
			},
		},
	},
})

-- =========================================================================
-- 4. 加载各组件的具体配置文件
-- =========================================================================
require("plugins.configs.cmp")
require("plugins.configs.lsp")
require("plugins.configs.ui")
require("plugins.configs.editor")
require("plugins.configs.tools")
