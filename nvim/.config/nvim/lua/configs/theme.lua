local api = vim.api

vim.o.background = "dark"
vim.opt.termguicolors = true

-- 换主题
-- =========================================================================
-- 1. Catppuccin 柔和猫咪主题配置
-- 说明：极具质感的低饱和度主题，内置了绝大多数主流插件的色彩适配。
-- =========================================================================
local status, catppuccin = pcall(require, "catppuccin")
if not status then
	return
end

catppuccin.setup({
	flavour = "mocha", -- 推荐选择暗色系：latte(明亮), frappe, macchiato, mocha(最暗)
	transparent_background = false, -- 是否开启背景透明
	term_colors = true,

	-- 🌟 自定义背景色调（改 base 即可；mantle/crust 保持逐层略深，保留层次感）
	color_overrides = {
		mocha = {
			base = "#161616", -- 背景主色
			mantle = "#181818", -- 侧边栏等次级背景
			crust = "#181818", -- 最深的底部背景
		},
	},

	-- 🌟 核心大招：一键开启对各大插件的色彩原生整合支持
	integrations = {
		gitsigns = true, -- 自动让 gitsigns 继承 catppuccin 的完美 git 色彩
		indent_blankline = {
			enabled = true,
			scope_color = "sky", -- 🌟 缩进线作用域自动使用好看了淡蓝色 (可改 blue, flamingo)
			colored_indent_levels = false,
		},
		noice = true, -- 完美兼容之前的 noice
		notify = true, -- 完美修复之前 notify 的背景颜色报错
	},
})

-- 立即启用该主题
vim.cmd.colorscheme("catppuccin")

-- =========================================================================
-- 🎨 分割线高亮（细实线，清晰可见）
-- =========================================================================
vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#565f89", bold = true })

-- 严防死守：确保分割线字符使用的是连续、无缝隙的细实线（避免部分终端渲染出虚线断层）
vim.opt.fillchars:append({
	vert = "│",
	vertright = "├",
	vertleft = "┤",
})

-- =============================================================================
-- 3.1 自定义你的专属 CursorLine 视觉样式
-- =============================================================================
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = function()
		-- 当前行下划线：松石蓝下划线，底色为 NONE
		vim.api.nvim_set_hl(0, "CursorLine", {
			fg = "NONE",
			bg = "NONE",
			underline = true,
			sp = "#00ffff", -- 完美的松石蓝下划线
			force = true,
		})

		-- 2. 括号强制去除斜体
		vim.api.nvim_set_hl(0, "@punctuation.bracket", { italic = false, force = true })

		-- 3. 浮动窗口透明
		vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE", force = true })

		-- 4. 浮动窗口边框
		vim.api.nvim_set_hl(0, "FloatBorder", {
			bg = "NONE",
			fg = "#7dcfff",
			force = true,
		})

		-- 5. snacks.indent 缩进线配色（复刻旧 indent-blankline：灰线 + 青色作用域）
		vim.api.nvim_set_hl(0, "SnacksIndent", { fg = "#292e42", nocombine = true, force = true })
		vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = "#2ac3de", nocombine = true, force = true })
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
