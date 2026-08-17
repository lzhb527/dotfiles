local api = vim.api

vim.o.background = "dark"
vim.opt.termguicolors = true

-- 换主题（双主题共存，<leader>ut 一键切换）
-- =========================================================================
-- 1. Tokyo Night 主题配置
-- 说明：与终端配色一致的高对比暗色主题，内置了绝大多数主流插件的色彩适配。
-- =========================================================================
local tn_status, tokyonight = pcall(require, "tokyonight")
if not tn_status then
	return
end

tokyonight.setup({
	style = "night", -- night(暗) / storm / day；与终端配色一致
	transparent = false, -- 是否开启背景透明
	terminal_colors = true, -- 同步终端 16 色（与 Alacritty Tokyo Night 一致）
	lualine_bold = true,

	-- 🌟 核心大招：一键开启对各大插件的色彩原生整合支持
	integrations = {
		blink_cmp = true,
		bufferline = true,
		gitsigns = true, -- 自动让 gitsigns 继承 tokyonight 的完美 git 色彩
		illuminate = true,
		lsp_trouble = true,
		lualine = true,
		markview = true,
		mason = true,
		mini = true,
		native_lsp = { enabled = true, underlines = {} },
		noice = true, -- 完美兼容之前的 noice
		notify = true, -- 完美修复之前 notify 的背景颜色报错
		snacks = true,
		treesitter = true,
		ts_rainbow2 = true, -- HiPhish/rainbow-delimiters 彩虹括号
		which_key = true,
	},
})

-- =========================================================================
-- 2. Catppuccin mocha 主题配置
-- 说明：柔和紫调暗色主题；背景通过 color_overrides 对齐终端底色。
-- =========================================================================
local cp_status, catppuccin = pcall(require, "catppuccin")
if not cp_status then
	return
end

catppuccin.setup({
	flavour = "mocha", -- latte(明亮) / frappe / macchiato / mocha(最暗)
	transparent_background = false, -- 是否开启背景透明
	term_colors = true,

	-- 🌟 自定义背景色调（与终端底色对齐，mantle/crust 保持逐层略深）
	color_overrides = {
		mocha = {
			base = "#1a1b26", -- 背景主色
			mantle = "#181818", -- 侧边栏等次级背景
			crust = "#181818", -- 最深的底部背景
		},
	},

	-- 🌟 核心大招：一键开启对各大插件的色彩原生整合支持
	integrations = {
		blink_cmp = true,
		gitsigns = true, -- 自动让 gitsigns 继承 catppuccin 的完美 git 色彩
		illuminate = true,
		lsp_trouble = true,
		markview = true,
		mason = true,
		mini = true,
		noice = true, -- 完美兼容之前的 noice
		notify = true, -- 完美修复之前 notify 的背景颜色报错
		rainbow_delimiters = true, -- HiPhish/rainbow-delimiters 彩虹括号
		snacks = true,
		which_key = true,
	},
})

-- 默认启用 Catppuccin mocha（可通过 <leader>ut 切换）
vim.cmd.colorscheme("catppuccin")

-- =========================================================================
-- 🎨 分割线高亮（细实线，清晰可见；跟随当前主题）
-- =========================================================================
vim.api.nvim_set_hl(0, "WinSeparator", { fg = require("configs.themes").get().winseparator, bold = true })
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		vim.api.nvim_set_hl(0, "WinSeparator", {
			fg = require("configs.themes").get().winseparator,
			bold = true,
		})
	end,
})

-- 严防死守：确保分割线字符使用的是连续、无缝隙的细实线（避免部分终端渲染出虚线断层）
vim.opt.fillchars:append({
	vert = "│",
	vertright = "├",
	vertleft = "┤",
})

-- =============================================================================
-- 3.1 自定义高亮（双主题感知，切换主题时自动跟随）
-- =============================================================================
local pal = require("configs.themes").get

vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = function()
		local c = pal()

		-- 1. 当前行下划线：松石蓝下划线，底色为 NONE
		vim.api.nvim_set_hl(0, "CursorLine", {
			fg = "NONE",
			bg = "NONE",
			underline = true,
			sp = "#00ffff", -- 完美的松石蓝下划线
			force = true,
		})

		-- 2. 鼠标/可视模式选中的背景色
		vim.api.nvim_set_hl(0, "Visual", { bg = c.visual_bg, fg = "#ffffff", force = true })

		-- 3. 括号强制去除斜体
		vim.api.nvim_set_hl(0, "@punctuation.bracket", { italic = false, force = true })

		-- 4. 浮动窗口透明
		vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE", force = true })

		-- 5. 浮动窗口边框
		vim.api.nvim_set_hl(0, "FloatBorder", {
			bg = "NONE",
			fg = c.float_border,
			force = true,
		})

		-- 6. snacks.indent 缩进线配色（灰线 + 青色作用域）
		vim.api.nvim_set_hl(0, "SnacksIndent", { fg = c.indent, nocombine = true, force = true })
		vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = c.indent_scope, nocombine = true, force = true })

		-- 7. 光标下单词高亮背景（LSP 内置 + vim-illuminate 独立组）
		vim.api.nvim_set_hl(0, "LspReferenceText", { bg = c.reference_bg, force = true })
		vim.api.nvim_set_hl(0, "LspReferenceRead", { bg = c.reference_bg, force = true })
		vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = c.reference_bg, force = true })
		vim.api.nvim_set_hl(0, "illuminatedWord", { bg = c.reference_bg, force = true })
		vim.api.nvim_set_hl(0, "illuminatedWordRead", { bg = c.reference_bg, force = true })
		vim.api.nvim_set_hl(0, "illuminatedWordWrite", { bg = c.reference_bg, force = true })

		-- 8. 注释文字调亮
		vim.api.nvim_set_hl(0, "Comment", { fg = c.comment, italic = true, force = true })
		vim.api.nvim_set_hl(0, "@comment", { fg = c.comment, italic = true, force = true })
	end,
})

-- 立即触发一次，确保当前已经加载的主题被应用该规则
vim.api.nvim_exec_autocmds("ColorScheme", {})

-- =============================================================================
-- 3.2 核心逻辑：控制仅在普通模式（Normal）激活下划线
-- =============================================================================
local cursorline_group = vim.api.nvim_create_augroup("DynamicCursorLine", { clear = true })

-- 离开普通模式（例如进入 i 插入模式, v 可视模式, t 终端模式等） -> 关闭下划线
vim.api.nvim_create_autocmd("ModeChanged", {
	group = cursorline_group,
	pattern = "n:*", -- 从 n (Normal) 变成任何其他模式
	callback = function()
		vim.opt.cursorline = false
	end,
})

-- 回到普通模式 -> 开启下划线
vim.api.nvim_create_autocmd("ModeChanged", {
	group = cursorline_group,
	pattern = "*:n", -- 从任何其他模式变成 n (Normal)
	callback = function()
		vim.opt.cursorline = true
	end,
})

-- 额外保障：刚打开文件或切换缓冲区时，如果是普通模式则默认开启
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
	group = cursorline_group,
	callback = function()
		if vim.api.nvim_get_mode().mode == "n" then
			vim.opt.cursorline = true
		else
			vim.opt.cursorline = false
		end
	end,
})
