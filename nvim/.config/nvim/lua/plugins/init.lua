-- =========================================================================
-- init.lua - 极致性能优化版
-- 每个插件的配置统一收敛到 lua/plugins/configs/<插件名>.lua
-- =========================================================================

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

-- 3. 插件配置列表（每个插件具体配置见 lua/plugins/configs/）
require("lazy").setup({
	-- =========================================================================
	-- 3.1 配色主题
	-- =========================================================================
	{ "catppuccin/nvim", name = "catppuccin", lazy = true },

	-- =========================================================================
	-- 3.2 现代化核心：代码高亮与语义解析引擎
	-- =========================================================================
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		config = require("plugins.configs.treesitter"),
	},

	-- =========================================================================
	-- 3.3 LSP、补全、代码检查与格式化
	-- =========================================================================
	{
		"neovim/nvim-lspconfig", -- LSP 核心(lsp.lua)
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim", -- 确保 Mason 先行加载安装工具
			"saghen/blink.cmp", -- 确保补全能力先行注入 LSP 客户端
		},
		config = require("plugins.configs.lsp"),
	},
	{
		"saghen/blink.cmp", -- 补全核心(blink.lua)，替代 nvim-cmp 全家桶
		version = "1.*", -- 稳定版 V1
		event = "InsertEnter",
		dependencies = {
			"rafamadriz/friendly-snippets", -- 内置 snippets 源自动加载
		},
		config = require("plugins.configs.blink"),
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = require("plugins.configs.autopairs"),
	},
	{
		"williamboman/mason.nvim",
		cmd = "Mason", -- 仅在调用 :Mason 时延迟加载
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim", -- 🌟 新增：全品类工具自动下载
		},
		config = require("plugins.configs.mason"),
	},
	{ "stevearc/conform.nvim", event = "BufWritePre", config = require("plugins.configs.conform") }, -- 🌟 替换掉旧的 ALE/Flake8，现代高效异步代码格式化器
	{
		"linux-cultist/venv-selector.nvim",
		ft = "python", -- Python 虚拟环境切换
		dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim" },
		config = require("plugins.configs.venv"),
	},

	-- =========================================================================
	-- 3.4 导航与搜索（全 Lua 升级）
	-- =========================================================================
	{
		"nvim-neo-tree/neo-tree.nvim", -- 🌟 完美替代 NERDTree，异步、颜值更高
		branch = "v3.x",
		cmd = "Neotree",
		keys = {
			{ "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Neo-tree" },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		opts = require("plugins.configs.neotree"),
	},
	{ "folke/flash.nvim", event = "VeryLazy", config = require("plugins.configs.flash") }, -- 🌟 完美替代 EasyMotion，极其高效酷炫的跳转
	{
		"nvim-telescope/telescope.nvim", -- 🌟 现代化搜索神器，完美融合 FZF
		cmd = "Telescope",
		keys = {
			{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
			{ "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
			{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" }, -- FZF 原生加速
		},
		config = require("plugins.configs.telescope"),
	},
	{ "lewis6991/gitsigns.nvim", event = { "BufReadPre", "BufNewFile" }, config = require("plugins.configs.gitsigns") }, -- 🌟 替代旧的 Fugitive，提供极致的侧边栏 Git 状态和操作
	{ "stevearc/aerial.nvim", cmd = "AerialToggle", config = require("plugins.configs.aerial") }, -- 🌟 完美替代 Tagbar，基于 LSP 的现代函数/类大纲导航
	{
		"folke/noice.nvim", -- 命令行与搜索栏重构
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
		config = require("plugins.configs.noice"),
	},

	-- =========================================================================
	-- 3.5 编辑增强
	-- =========================================================================
	{ "lukas-reineke/indent-blankline.nvim", event = { "BufReadPost", "BufNewFile" }, main = "ibl", config = require("plugins.configs.ibl") }, -- 🌟 替换旧的 indentLine，基于 Lua 且完美适配 Treesitter
	{ "HiPhish/rainbow-delimiters.nvim", event = { "BufReadPost", "BufNewFile" }, config = require("plugins.configs.rainbow") }, -- 🌟 替换旧的 rainbow，基于 Treesitter 的高性能彩虹括号
	{ "catgoose/nvim-colorizer.lua", event = "BufReadPre", opts = require("plugins.configs.colorizer") }, -- 颜色高亮（活跃维护的新版 fork，全文件类型高亮）
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		-- 🌟 cmd 懒加载：F8/F9/F10 与 <leader>t* 映射直接调用 ToggleTerm 命令，
		-- 用 cmd 拦截能在执行命令前先加载插件，避免 E492: Not an editor command
		cmd = { "ToggleTerm", "ToggleTermToggleAll" },
		keys = { "<leader>t" },
		config = require("plugins.configs.toggleterm"),
	}, -- 🌟 替换旧的 floaterm，功能极度强大的浮动/多终端管理
	{ "folke/snacks.nvim", event = "VeryLazy", config = require("plugins.configs.snacks") },
	{
		"folke/persistence.nvim", -- 会话保存/恢复（激活 dashboard 的 s 键：Restore Session）
		event = "BufReadPre",
		opts = {
			options = { "buffers", "win", "tabpages", "folds", "curdir" },
			save_dir = vim.fn.stdpath("state") .. "/sessions/",
		},
		keys = {
			{ "<leader>qs", function() require("persistence").save() end, desc = "保存会话" },
			{ "<leader>ql", function() require("persistence").load() end, desc = "恢复会话" },
			{ "<leader>qd", function() require("persistence").stop() end, desc = "停止自动保存" },
		},
	},
	{
		"chrisgrieser/nvim-origami",
		event = "VeryLazy",
		opts = {},
		init = function()
			vim.opt.foldlevel = 99
			vim.opt.foldlevelstart = 99
		end,
	},
	{
		"mg979/vim-visual-multi",
		keys = { "<C-m>" },
		config = require("plugins.configs.visual-multi"),
	},

	-- =========================================================================
	-- 3.6 UI 增强
	-- =========================================================================
	{
		"nvim-lualine/lualine.nvim",
		event = "UIEnter",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = require("plugins.configs.lualine"),
	}, -- 状态栏
	{
		"akinsho/bufferline.nvim",
		event = "UIEnter",
		dependencies = { "nvim-web-devicons" },
		config = require("plugins.configs.bufferline"),
	}, -- 缓冲区多标签页
	{
		"folke/which-key.nvim", -- 按键提示
		event = "VeryLazy",
		opts = require("plugins.configs.whichkey"),
	},

	-- =========================================================================
	-- 3.7 诊断美化（在光标当前行优雅显示报错详情）
	-- =========================================================================
	{
		"folke/trouble.nvim",
		cmd = "Trouble", -- 懒加载：只有在调用 Trouble 命令时才加载
		opts = require("plugins.configs.trouble"),
	},
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = "LspAttach", -- 当 LSP 启动时再懒加载
		priority = 1000, -- 保证优先级
		config = require("plugins.configs.tiny-inline-diagnostic"),
	},

	-- =========================================================================
	-- 3.8 代码调试 (DAP)
	-- =========================================================================
	{
		"mfussenegger/nvim-dap", -- 调试核心引擎
		event = "VeryLazy",
		dependencies = {
			"jay-babu/mason-nvim-dap.nvim", -- 自动安装/管理各语言调试器
		},
		config = require("plugins.configs.dap"),
	},
	{
		"jay-babu/mason-nvim-dap.nvim", -- 从 Mason 自动安装调试器（setup 在 dap.lua 内调用）
		lazy = true,
		dependencies = { "williamboman/mason.nvim" },
	},
	{
		"rcarriga/nvim-dap-ui", -- 调试 UI（变量/断点/调用栈/REPL）
		event = "VeryLazy",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
		},
		config = require("plugins.configs.dapui"),
	},
	{
		"theHamsta/nvim-dap-virtual-text", -- 调试时行内显示变量值
		event = "VeryLazy",
		dependencies = { "mfussenegger/nvim-dap" },
		opts = {},
	},
}, {
	-- Lazy 的全局 UI 配置
	ui = { border = "rounded" },
	performance = {
		cache = {
			enabled = true, -- 启用缓存加速
		},
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
			checker = {
				enabled = true,
				notify = false,
				frequency = 86400, -- 24小时检查一次
			},
			change_detection = {
				notify = false, -- 不提示配置变化
			},
		},
	},
})
