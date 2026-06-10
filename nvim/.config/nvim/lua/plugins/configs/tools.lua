local map = vim.keymap.set

-- =============================================================================
-- 1. Telescope.nvim 配置 (全面替代 FZF 环境变量)
-- =============================================================================
local telescope_status, telescope = pcall(require, "telescope")
if telescope_status then
	telescope.setup({
		defaults = {
			layout_strategy = "horizontal",
			layout_config = {
				horizontal = { preview_width = 0.55 },
			},
			sorting_strategy = "ascending", -- 让最新搜到的结果排在最上面
			border = true,
			file_ignore_patterns = {
				"node_modules/",
				"%.git/",
				"client/node_modules/",
				"__pycache__/",
				"venv/",
				"%.env",
			},
		},
	})

	-- 【快捷键绑定】：Telescope 现代化快速检索
	map("n", "<leader>ff", "<Cmd>Telescope find_files<CR>", { desc = "查找文件" })
	map("n", "<leader>fg", "<Cmd>Telescope live_grep<CR>", { desc = "全局文本搜索" })
	map("n", "<leader>fb", "<Cmd>Telescope buffers<CR>", { desc = "查找缓冲区" })
end

-- =============================================================================
-- 2. conform.nvim 配置 (🌟 Ruff 超级一体化流水线托管版)
-- =============================================================================
local conform_status, conform = pcall(require, "conform")
if conform_status then
	-- ---------------------------------------------------------------------
	-- 🌟 【核心大招】自定义超级一体化 Ruff 格式化器
	-- ---------------------------------------------------------------------
	-- 默认的 ruff_organize_imports 有时会因为 Neovim 根目录判定或 Ruff 版本升级而静默失效。
	-- 这里我们直接写死最底层的命令行参数，强行让 Ruff 在一次调用中同时干完“删导包”和“刷空格”。
	conform.formatters.ruff_all_in_one = {
		command = "ruff",
		-- format: 负责格式化空格和缩进
		-- --line-ending native: 保持换行符正常
		-- --stdin-filename: 让 Ruff 知道当前在处理什么文件以触发相应规则
		args = { "format", "--force-exclude", "--stdin-filename", "$FILENAME", "-" },
	}

	-- 自定义一个专门用来删除未使用导包的底层修复器作为前置流水线
	conform.formatters.ruff_fix_unused = {
		command = "ruff",
		-- check: 运行静态检查
		-- --select F401,I: 精准锁定 F401(未使用导入) 和 I(导入排序)
		-- --fix: 强行自动修复（删除）它们
		args = { "check", "--select", "F401,I", "--fix", "--force-exclude", "--stdin-filename", "$FILENAME", "-" },
	}

	-- ---------------------------------------------------------------------
	-- 核心 Setup 配置
	-- ---------------------------------------------------------------------
	conform.setup({
		-- 🌟 文件类型与格式化器的一对一/多对多映射字典
		formatters_by_ft = {
			lua = { "stylua" },

			-- 🌟 终极必杀连招：保存或手动调用时，先执行强行删导包，再执行强行刷空格！
			python = { "ruff_fix_unused", "ruff_all_in_one" },

			sh = { "shfmt" }, -- 顺便帮您的 Bash 脚本也加上现代格式化
			yaml = { "prettier" },
		},

		-- 🌟 开启自动保存格式化（阻塞同步落盘）
		format_on_save = {
			timeout_ms = 800, -- 适当将超时放大到 800ms，给删导包留出充裕的命令行执行时间
			lsp_fallback = true, -- 如果工具链挂了，尝试降级使用 LSP 原生格式化
		},
	})

	-- ---------------------------------------------------------------------
	-- 【快捷键绑定】：一键调用 conform 进行安全的后台全异步格式化
	-- ---------------------------------------------------------------------
	-- 兼容你可能拥有的自定义全局 map 函数；如果没有，则自动降级使用原生 API
	local key_map = type(map) == "function" and map
		or function(mode, lhs, rhs, opts)
			vim.keymap.set(mode, lhs, rhs, opts)
		end

	key_map("n", "<leader>fm", function()
		conform.format({ async = true, lsp_fallback = true })
	end, { desc = "Conform 异步格式化当前文件" })
end

-- =============================================================================
-- 3. 现代纯 Lua 诊断图标配置 (彻底规避 E239 报错，保留您自定义的空格 HINT)
-- =============================================================================
vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "✗", -- 错误图标
			[vim.diagnostic.severity.WARN] = "⚡", -- 警告图标
			[vim.diagnostic.severity.HINT] = "  ", -- 提示图标（保留您精简后的两个空格样式）
			[vim.diagnostic.severity.INFO] = "", -- 信息图标
		},
	},
	float = { border = "rounded" },
})

-- =============================================================================
-- 4. Aerial.nvim 代码标签树配置 (🌟 完美降维打击替代旧的 Tagbar)
-- =============================================================================
local aerial_status, aerial = pcall(require, "aerial")
if aerial_status then
	aerial.setup({
		layout = {
			max_width = { 40, 0.2 },
			width = 30, -- 对应原本的 tagbar_width = 30
		},
		close_on_select = false, -- 选中时不自动关闭
		show_guides = true, -- 显示漂亮的树状引导线
		filter_kind = false, -- 完美显示所有函数、类、变量

		-- 🌟 核心修复：当打开支持的语言（如 Python）时，在后台自动激活 Aerial 服务
		on_attach = function(bufnr)
			-- 💡 这样一打开文件，后台的数据导轨就已经就绪，绝不会再报 No items found！
			-- 如果你之前绑定了诸如 { 和 } 在函数间跳跃，这里会自动打通。
		end,

		-- 强力推荐：确保后端首选依赖刚才配好的 Tree-sitter
		backends = { "treesitter", "lsp", "markdown", "man" },
	})

	-- 【快捷键绑定】：🌟 继承你的习惯，按下 F8 键一键开关侧边函数结构树
	map("n", "<F12>", "<cmd>AerialToggle! left<CR>", { desc = "切换函数结构树" })
end

-- =============================================================================
-- 5. Tree-sitter 配置
-- =============================================================================
-- lua/config/treesitter_options.lua
local status, configs = pcall(require, "nvim-treesitter.configs")
if not status then
	return
end

configs.setup({
	-- 🌟 确保每次启动或更新时，自动在后台下载好 Python 解析器
	ensure_installed = { "python", "lua", "vim", "vimdoc", "markdown" },

	-- 自动安装缺失的解析器
	auto_install = true,

	highlight = {
		enable = true, -- 🔴 核心：必须为 true 才能让 Python 高亮生效
		additional_vim_regex_highlighting = false,
	},

	-- 开启基于 Tree-sitter 的智能缩进
	indent = {
		enable = true,
	},
})

-- =========================================================================
-- 11. trouble.nvim 现代代码诊断与结果列表可视化 (v3)
-- 说明：官方仓库 folke/trouble.nvim，一键将报错、警告、TODO 聚合成精美面板。
-- =========================================================================
local status, trouble = pcall(require, "trouble")
if not status then
	return
end

trouble.setup({
	-- 🌟 新版 v3 核心：指定默认行为和外观
	auto_close = false, -- 当列表空了之后，是否自动关闭 Trouble 面板
	auto_open = false, -- 当有代码报错时，是否自动弹窗（通常保持 false 避免干扰写代码）
	restore = true, -- 当重新打开面板时，恢复上一次的折叠状态
	follow = true, -- 列表光标自动跟随主窗口光标所在的代码位置
	indent_guides = true, -- 在报错树状图左侧画出漂亮的层级对齐虚线
	max_items = 200, -- 面板内最大显示条目数

	-- 视觉图标配置（保持与主流图标对齐）
	icons = {
		indent = {
			top = "│ ",
			middle = "├─ ",
			last = "└─ ",
			fold_open = " ",
			fold_closed = " ",
			ws = "  ",
		},
	},

	-- 节制多余视觉：多窗口分屏时，确保边界线整洁
	win = {
		wo = {
			winhighlight = "Normal:TroubleNormal,SignColumn:TroubleSignColumn",
		},
	},
})
