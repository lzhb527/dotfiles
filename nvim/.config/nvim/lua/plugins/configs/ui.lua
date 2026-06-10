-- =========================================================================
-- 安全加载：防止首次启动、插件尚未同步克隆完时弹出致命报错
-- =========================================================================
local lualine_status, lualine = pcall(require, "lualine")
local bufferline_status, bufferline = pcall(require, "bufferline")
local colorizer_status, colorizer = pcall(require, "colorizer")

-- =========================================================================
-- 1. Lualine 状态栏配置
-- =========================================================================
if lualine_status then
	-- Python 虚拟环境检测组件
	local function python_venv()
		-- 1. venv / virtualenv / poetry
		local venv = os.getenv("VIRTUAL_ENV")
		if venv and venv ~= "" then
			return "   " .. vim.fn.fnamemodify(venv, ":t")
		end

		-- 2. conda / mamba
		local conda = os.getenv("CONDA_DEFAULT_ENV")
		if conda and conda ~= "" then
			return "   " .. conda
		end

		return ""
	end

	lualine.setup({
		options = {
			theme = "auto",
			component_separators = { left = "", right = "" },
			section_separators = { left = "", right = "" },
			-- 🌟 同步修正：将过时的 NvimTree 更改为现代的 neo-tree
			disabled_filetypes = { "neo-tree", "dashboard" },
			globalstatus = true,
			refresh = { statusline = 1000 },
		},
		sections = {
			lualine_a = { "mode" },
			lualine_b = { "branch", "diff" },
			lualine_c = { "filename", python_venv },
			lualine_x = { "encoding", "fileformat", "filetype" },
			lualine_y = { "progress" },
			lualine_z = { "location" },
		},
	})
end

-- =========================================================================
-- 2. Bufferline 缓冲区标签配置
-- =========================================================================
-- lua/plugins/configs/ui.lua
local status_ok, bufferline = pcall(require, "bufferline")
if not status_ok then
	return
end

bufferline.setup({
	options = {
		mode = "buffers", -- 管理缓冲区
		style_preset = bufferline.style_preset.minimal, -- 🌟 极简预设：去掉刺眼的粗边框，符合老派审美
		numbers = "none", -- 隐藏没用的数字序号
		close_command = "bdelete! %d", -- 联动右键/关闭命令
		right_mouse_command = "bdelete! %d",

		-- 视觉增强
		indicator = {
			style = "underline", -- 当前选中的标签下方显示一条精致的下划线
		},
		buffer_close_icon = "󰅖",
		modified_icon = "●",
		close_icon = "",
		left_trunc_marker = "",
		right_trunc_marker = "",

		-- 完美桥接你的 Neo-tree 文件树，让左侧自动留出空白，视觉极度舒适
		offsets = {
			{
				filetype = "neo-tree",
				text = "  FILE EXPLORER",
				text_align = "center",
				separator = true,
			},
		},

		-- 基础行为
		diagnostics = "nvim_lsp", -- 顶栏直接显示对应文件的 LSP 报错状态
		always_show_bufferline = true,
	},

	-- =========================================================================
	-- 🎨 Molokai 专属色彩救赎 (消除割裂感的灵魂)
	-- =========================================================================
	highlights = {
		-- 未选中标签的背景：强行隐形，使用 Molokai 经典的深炭黑底色
		fill = {
			bg = { attribute = "bg", highlight = "Normal" },
		},
		background = {
			bg = { attribute = "bg", highlight = "Normal" },
			fg = "#75715E", -- 使用 Molokai 标志性的复古哑光灰作为未激活文字色
		},

		-- 当前选中的标签：微微调亮，拉开层次，文字继承 Molokai 纯正的青绿高亮
		buffer_selected = {
			bg = "#232526", -- 经典的 Molokai 选中行/状态栏略亮炭黑
			fg = "#66D9EF", -- 标志性冰冷青绿，一眼看出当前在写哪个文件
			bold = true,
		},

		-- 侧边分割线：克制低调
		separator = {
			fg = "#232526",
			bg = { attribute = "bg", highlight = "Normal" },
		},
		separator_selected = {
			fg = "#232526",
			bg = "#232526",
		},

		-- 提示/报错图标在顶栏的颜色适配
		info_diagnostic_selected = { fg = "#66D9EF", bg = "#232526", bold = true },
		warning_diagnostic_selected = { fg = "#FD971F", bg = "#232526", bold = true }, -- 橙黄
		error_diagnostic_selected = { fg = "#F92672", bg = "#232526", bold = true }, -- 霓虹粉红
	},
})

-- =========================================================================
-- 3. Dashboard 启动页配置
-- =========================================================================
local dashboard_status, dashboard = pcall(require, "dashboard")
if dashboard_status then
	dashboard.setup({
		theme = "hyper",
		config = {
			header = {
				"                                                     ",
				"  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
				"  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
				"  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
				"  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
				"  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
				"  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
				"                                                     ",
			},
			center = {
				{ icon = "  ", desc = "新建文件", action = "enew", key = "n" },
				{ icon = "    ", desc = "最近文件", action = "Telescope oldfiles", key = "r" }, -- 🌟 适配 Telescope 的最近文件搜索
				{ icon = "  ", desc = "编辑配置", action = "edit ~/.config/nvim/init.lua", key = "c" },
				{ icon = "    ", desc = "退出", action = "qa", key = "q" },
			},
			footer = { " Neovim " },
			shortcut = {
				{ desc = "   UPDATE", group = "@property", action = "Lazy update", key = "u" },
			},
			project = { enable = false },
		},
		hide = { statusline = true, tabline = true, winbar = true },
	})
end

-- =========================================================================
-- 4. Colorizer 颜色高亮配置（🌟 彻底修复 expected table, got string 报错）
-- =========================================================================
local colorizer_status, colorizer = pcall(require, "colorizer")
if colorizer_status then
	colorizer.setup({
		-- 🌟 修正：将裸字符串改为以文件类型（Filetype）为 Key 的 Table 格式
		["*"] = {
			css = true,
			html = true,
		},
		css = { rgb_fn = true },
		html = { names = true },
	})
end

-- =========================================================================
-- 5. 现代缩进线 (indent-blankline v3) 配置
-- =========================================================================
local ibl_status, ibl = pcall(require, "ibl")
if ibl_status then
	-- =========================================================================
	-- 🎨 设定缩进线颜色组（完美适配 Tokyo Night 霓虹色调）
	-- =========================================================================
	local set_hl = vim.api.nvim_set_hl

	-- 1. 普通缩进线的颜色：设为非常低调的暗灰色，若隐若现不干扰视线
	set_hl(0, "IblIndent", { fg = "#292e42", nocombine = true })

	-- 2. 🌟 当前函数/代码块的作用域高亮颜色（核心修改项）
	-- 这里推荐使用 Tokyo Night 标志性的青色 (#2ac3de) 或霓虹蓝 (#7aa2f7)
	set_hl(0, "IblScope", { fg = "#2ac3de", nocombine = true })

	ibl.setup({
		indent = {
			char = "┊", -- 经典的细实线
			highlight = "IblIndent", -- 指定普通缩进线的颜色组
		},
		scope = {
			enabled = true, -- 动态高亮当前光标所在的代码块
			show_start = true, -- 是否在函数开头画一根横线
			show_end = true,
			highlight = "IblScope", -- 指定当前活动作用域的颜色组
		},
		exclude = {
			filetypes = {
				"dashboard",
				"alpha",
				"neo-tree", -- 🌟 同步修正：防止缩进线破坏 Neo-tree 侧边栏的树状视觉效果
				"lazy",
				"mason",
				"terminal",
				"help",
				"notify",
				"toggleterm",
			},
		},
	})
end

-- =========================================================================
-- 6. 现代彩虹括号 (rainbow-delimiters) 配置
-- =========================================================================
local rb_status, rb = pcall(require, "rainbow-delimiters")
if rb_status then
	vim.g.rainbow_delimiters = {
		strategy = {
			[""] = rb.strategy["global"],
		},
		query = {
			[""] = "rainbow-delimiters",
		},
		highlight = {
			"RainbowDelimiterRed",
			"RainbowDelimiterYellow",
			"RainbowDelimiterBlue",
			"RainbowDelimiterOrange",
			"RainbowDelimiterGreen",
		},
	}

	-- 完美同步你原本的 Gruvbox 配色
	local colors = {
		Red = "#fb4934",
		Yellow = "#b8bb26",
		Blue = "#83a598",
		Orange = "#d3869b",
		Green = "#8ec07c",
	}
	for role, color in pairs(colors) do
		vim.api.nvim_set_hl(0, "RainbowDelimiter" .. role, { fg = color })
	end
end

-- =========================================================================
-- 7 .~/.config/nvim/lua/plugins/configs/neotree.lua
-- =========================================================================
local status, neotree = pcall(require, "neo-tree")
if not status then
	return
end

neotree.setup({
	close_if_last_window = false,
	popup_border_style = "rounded",
	enable_git_status = true,
	enable_diagnostics = true,

	-- =========================================================================
	-- 🌟 完美拆离合并：Neo-tree 顶部的 File / Bufs / Git 标签页切换栏
	-- =========================================================================
	source_selector = {
		winbar = true, -- 在文件树顶部开启标签页栏
		statusline = false, -- 关闭底部状态栏的显示
		show_scrolled_by = false, -- 隐藏多余的滚动提示
		sources = { -- 显式定义并美化显示的三个标签页源
			{ source = "filesystem", display_name = "  File " },
			{ source = "buffers", display_name = "  Bufs " },
			{ source = "git_status", display_name = "  Git " },
		},
	},

	-- =========================================================================
	-- 核心交互行为控制
	-- =========================================================================
	window = {
		position = "left",
		width = 30, -- 固定侧边栏物理宽度为 30
		mappings = {

			-- 💡 极客技巧：当光标停在顶部的 File/Bufs/Git 标签栏上或普通目录下时，
			-- 按下键盘的 < 和 > 键（也就是 Shift+, 和 Shift+.）就可以在三个标签页之间无感来回切换！
			["<"] = "prev_source",
			[">"] = "next_source",

			-- 🌟 完美修复：普通目录状态下交由底层原生按键处理，从而彻底消除报错警告
			["<C-j>"] = "none",
			["<C-k>"] = "none",
		},
	},

	filesystem = {
		-- 🌟 搜索框高级联动：只有当你主动按 f 键唤出搜索框并打完字后，
		-- 按 Ctrl+j / Ctrl+k 才能在输入框里直接控制下方文件树的光标跳跃！
		fuzzy_finder_mappings = {
			["<C-j>"] = "move_cursor_down",
			["<C-k>"] = "move_cursor_up",
		},
		bind_to_cwd = true,
		use_libuv_file_watcher = true,
		filtered_items = {
			hide_dotfiles = false, -- 让 .gitignore 等隐藏文件默认直接可见
			hide_gitignored = true, -- 自动将 git 忽略的文件夹置灰，保持视觉绝对干净
		},
		follow_current_file = {
			enabled = true, -- 智能追踪：主窗口切到哪，左侧文件树自动跨目录高亮到哪
		},
	},
})

-- =========================================================================
-- 8 noice 核心交互行为控制 (Presets & Integration)
-- 说明：Noice 的预设组合拳与深度整合配置。
-- =========================================================================
local status, noice = pcall(require, "noice")
if not status then
	return
end

-- 🌟 核心修复：在 noice 启动前，强行为依赖的 notify 插件兜底指定背景色
-- 这样在启用透明终端或 Tokyo Night 主题时，绝对不会再触发黄色警告弹窗。
pcall(function()
	require("notify").setup({
		background_colour = "#1a1b26", -- 精准对齐 Tokyo Night 官方暗底色
	})
end)

noice.setup({
	presets = {
		bottom_search = true, -- 底部搜索栏：使 / 和 ? 搜索窗口停靠在底部，更符合原生习惯
		command_palette = true, -- 命令面板：让 : 命令行变为屏幕中央的悬浮面板（类似全局搜索）
		long_message_to_split = true, -- 长消息分屏：当报错或提示文本行数过长时，自动送入分屏而不阻塞屏幕
		lsp_doc_border = true, -- 文档边框：强制为 LSP Hover（如 K 键提示）的文档窗口添加精美边框
	},

	-- =========================================================================
	-- LSP 深度整合设置 (LSP Integration)
	-- 说明：允许 Noice 接管 Neovim 内置的 LSP 渲染器。
	-- =========================================================================
	lsp = {
		override = {
			-- 覆盖 Neovim 默认的 Markdown 转换与样式渲染，改用 Noice 视觉引擎
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			-- 覆盖补全插件（如 nvim-cmp / blink.cmp）的文档处理，保持 UI 风格高度统一
			["cmp.entry.get_documentation"] = true,
		},

		-- 关闭 noice 对诊断（报错信息）的接管与渲染
		diagnostics = {
			enabled = false,
		},

		-- 控制签名帮助（函数参数弹窗行为）
		signature = {
			enabled = false,
			opts = {
				-- 强制底层 Markdown 渲染器不渲染任何后续文档行，只留 1 行核心函数名和参数！
				size = { max_height = 1 },
				win_options = {
					wrap = false, -- 严防死守，不让它换行扩展
				},
			},
		},
	},

	-- =========================================================================
	-- 消息路由与过滤规则 (Routes)
	-- 说明：Noice 强大的消息过滤器。
	-- =========================================================================
	routes = {
		{
			-- 过滤无用杂音：静音文件保存（如 :w）时底部频繁出现的 "written" 提示
			filter = {
				event = "msg_show",
				find = "written",
				kind = "confirm", -- 拦截 confirm 类型，即 press-enter
			},
			opts = { skip = true }, -- skip = true 代表直接拦截并丢弃该消息
		},
	},
})

-- =========================================================================
-- 9  ~/.config/nvim/lua/plugins/configs/whichkey.lua
-- =========================================================================

local ok, wk = pcall(require, "which-key")
if not ok then
	return
end

wk.setup({
	-- 1. 采用官方推荐的现代高密度现代布局
	preset = "modern",

	win = {
		border = "rounded", -- 悬浮窗边框样式
		-- ⭐️ 关键：将宽度放大到屏幕的 96%，给多列横向平铺留足物理空间
		-- 这样你的“查看所有快捷键全览”等长中文绝对不会挤压换行
		padding = { 1, 2 }, -- 内边距：上下 1 字符，左右 2 字符
	},

	-- 2. ⭐️ 官方标准布局控制
	layout = {
		align = "center", -- 将键位在浮窗内居中/平铺对齐
		spacing = 3, -- 降低键位和描述之间的空格间距，横向更紧凑
	},
})

-- =========================================================================
-- 9 gitsigns Git 状态集成与交互控制 (Tokyo Night 专属霓虹色调版)
-- 说明：实时显示代码修改状态，完美提取并对齐 Tokyo Night 官方原装色值。
-- =========================================================================
local status, gitsigns = pcall(require, "gitsigns")
if not status then
	return
end

-- =========================================================================
-- 🎨 动态提取或精准绑定 Tokyo Night 官方 Git 调色盘
-- =========================================================================
local set_hl = vim.api.nvim_set_hl

-- 1. 如果您的配置能成功加载 tokyonight 颜色模块，则动态提取官方最准的颜色
local has_tk_colors, tk_colors = pcall(require, "tokyonight.colors")
if has_tk_colors then
	local c = tk_colors.setup() -- 自动识别您当前的样式(storm, night, moon)
	set_hl(0, "GitSignsAdd", { fg = c.git.add }) -- 官方柔和绿 (#449dab)
	set_hl(0, "GitSignsChange", { fg = "#E0AF68" }) -- 官方霓虹蓝/浅蓝 (#61afef / #2ac3de)
	set_hl(0, "GitSignsDelete", { fg = "#ff0000" }) -- 官方暗霓虹红 (#914c54)
	set_hl(0, "GitSignsTopdelete", { fg = "#ff0000" })
	set_hl(0, "GitSignsChangedelete", { fg = c.git.change })
	set_hl(0, "GitSignsUntracked", { fg = c.dark5 }) -- 官方未追踪灰色
else
	-- 2. 备用安全色：万一模块未加载，直接写入硬编码的 Tokyo Night 官方经典十六进制色值
	set_hl(0, "GitSignsAdd", { fg = "#449dab" }) -- Tokyo Night 经典绿
	set_hl(0, "GitSignsChange", { fg = "#2ac3de" }) -- Tokyo Night 经典蓝/青
	set_hl(0, "GitSignsDelete", { fg = "#914c54" }) -- Tokyo Night 经典红
	set_hl(0, "GitSignsTopdelete", { fg = "#914c54" })
	set_hl(0, "GitSignsChangedelete", { fg = "#2ac3de" })
	set_hl(0, "GitSignsUntracked", { fg = "#3b4261" })
end

gitsigns.setup({
	-- 1. 符号栏图标与高亮组绑定
	signs = {
		add = { text = "┃", hl = "GitSignsAdd" },
		change = { text = "┃", hl = "GitSignsChange" },
		delete = { text = "_", hl = "GitSignsDelete" },
		topdelete = { text = "‾", hl = "GitSignsTopdelete" },
		changedelete = { text = "~", hl = "GitSignsChangedelete" },
		untracked = { text = "┆", hl = "GitSignsUntracked" },
	},

	-- 额外的行号和背景高亮开关
	signcolumn = true,
	numhl = false, -- 保持 false，否则 Tokyo Night 的精美行号会被覆盖
	linehl = false,

	-- 2. 行级实时 Blame 提示 (光标停顿后在行尾显示作者和时间)
	current_line_blame = false,
	current_line_blame_opts = {
		virt_text = true,
		virt_text_pos = "eol", -- 显示在行尾
		delay = 500, -- 光标停顿 500 毫秒后显示
	},

	-- 3. 快捷键绑定映射 (Keymaps)
	on_attach = function(bufnr)
		local function map(mode, l, r, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, l, r, opts)
		end

		-- 跳转修改块 (Navigation)
		map("n", "]c", function()
			if vim.wo.diff then
				vim.cmd.feedkeys(vim.api.nvim_replace_termcodes("]c", true, true, true), "n", false)
			else
				gitsigns.nav_hunk("next")
			end
		end, { desc = "下一个 Git 修改块" })

		map("n", "[c", function()
			if vim.wo.diff then
				vim.cmd.feedkeys(vim.api.nvim_replace_termcodes("[c", true, true, true), "n", false)
			else
				gitsigns.nav_hunk("prev")
			end
		end, { desc = "上一个 Git 修改块" })

		-- 核心操作 (Actions)
		map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "预览当前修改块" })
		map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "撤销当前修改块 (Reset)" })
		map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "暂存当前修改块 (Stage)" })
		map("n", "<leader>hb", function()
			gitsigns.blame_line({ full = true })
		end, { desc = "查看当前行完整 Blame 弹窗" })
		map("n", "<leader>hd", gitsigns.diffthis, { desc = "对比当前文件与 Git 版本的差异" })
	end,
})
