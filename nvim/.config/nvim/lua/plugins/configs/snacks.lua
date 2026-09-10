-- =========================================================================
-- snacks.nvim 配置（状态列 + 启动页 Dashboard）
-- =========================================================================
return function()
	-- 折叠列设为 0：Snacks 会自己画折叠箭头，避免与原生折叠列叠加
	vim.opt.foldcolumn = "0"

	local snacks_status, snacks = pcall(require, "snacks")
	if not snacks_status then
		return
	end

	-- tte 动画 Logo（终端段用，依赖 brew install tte）
	local tte_logo = [[
    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀     ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⠛⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣿⣧⣾⣿⣿⣿⣦⠀⠀⣠⣶⣿⣿⣿⣿⣦⡀⠀⢀⣴⣾⣿⣿⣿⣷⣦⠀⠸⣿⣿⡆⠀⠀⣼⣿⡟⠀⣿⣿⡇⠀⣿⣿⣷⣾⣿⣿⣷⣴⣾⣿⣿⣿⣦
⣿⣿⣿⠁⠀⠹⣿⣿⡄⢰⣿⣿⣃⣀⣀⣻⣿⣷⠀⣾⣿⡟⠁⠀⠈⢿⣿⣧⠀⢻⣿⣷⠀⢰⣿⣿⠁⠀⣿⣿⡇⠀⣿⣿⡟⠁⠀⢻⣿⣿⠁⠀⢹⣿⣿
⣿⣿⡇⠀⠀⠀⣿⣿⡇⢸⣿⣿⠿⠿⠿⠿⠿⠿⠀⣿⣿⡇⠀⠀⠀⢸⣿⣿⠀⠈⣿⣿⣇⣿⣿⠇⠀⠀⣿⣿⡇⠀⣿⣿⡇⠀⠀⢸⣿⣿⠀⠀⢸⣿⣿
⣿⣿⡇⠀⠀⠀⣿⣿⡇⠘⢿⣿⣦⣄⣠⣼⣿⡟⠀⠹⣿⣿⣤⣀⣴⣿⣿⠇⠀⠀⠸⣿⣿⣿⡟⠀⠀⠀⣿⣿⡇⠀⣿⣿⡇⠀⠀⢸⣿⣿⠀⠀⢸⣿⣿
⠛⠛⠃⠀⠀⠀⠛⠛⠃⠀⠈⠙⠻⠿⠿⠛⠋⠀⠀⠀⠉⠛⠿⠿⠿⠛⠁⠀⠀⠀⠀⠛⠛⠛⠃⠀⠀⠀⠛⠛⠃⠀⠛⠛⠃⠀⠀⠘⠛⠛⠀⠀⠘⠛⠛
  ]]

	-- tte 子命令（随机挑一个）
	local tte_subcommands = {
		"beams --beam-delay 5 --beam-row-speed-range 20-60 --beam-column-speed-range 8-12",
		-- "beams",
		-- "binarypath",
		-- "blackhole",
		-- "bouncyballs",
		-- "bubbles",
		-- "burn",
		-- "colorshift",
		-- "crumble",
		-- "decrypt",
		-- "errorcorrect",
		-- "expand",
		-- "fireworks",
		-- "highlight",
		-- "laseretch",
		-- "matrix",
		-- "middleout",
		-- "orbittingvolley",
		-- "overflow",
		-- "pour",
		-- "print",
		-- "rain",
		-- "randomsequence",
		-- "rings",
		-- "scattered",
		-- "slice",
		-- "slide",
		-- "smoke",
		-- "spotlights",
		-- "spray",
		-- "swarm",
		-- "sweep",
		-- "synthgrid",
		-- "thunderstorm",
		-- "unstable",
		-- "vhstape",
		-- "waves",
		-- "wipe",
	}
	math.randomseed(os.time())
	local tte_cmd = "echo -e "
		.. vim.fn.shellescape(vim.trim(tte_logo))
		.. " | tte --anchor-canvas s "
		.. tte_subcommands[math.random(#tte_subcommands)]
		.. " --final-gradient-direction diagonal"

	vim.opt.statuscolumn = [[%!v:lua.Snacks.statuscolumn()]]

	-- 🌟 核心修复 2：彻底置空原生的折叠连接线
	vim.opt.fillchars = {
		foldopen = "", -- 展开时的现代箭头
		foldclose = "", -- 折叠时的现代箭头
		fold = " ", -- 彻底消除原生的纵向连接竖线
		foldsep = " ", -- 彻底消除原生的纵向分隔竖线
	}

	-- dashboard sections
	local dashboard_sections = {
		{
			section = "terminal",
			cmd = tte_cmd, -- tte 动画 Logo
			height = 8,
			padding = 1,
			ttl = 0, -- 每次启动都实况播放动画
		},
		{ section = "header" },
		{ section = "recent_files", indent = 3, padding = 1 },
		{ section = "keys", indent = 3, padding = 1 },
		{ section = "startup", indent = 3, icon = " 󰛕 " },
	}

	snacks.setup({
		-- indent：缩进线 + 当前作用域高亮
		indent = {
			enabled = true,
			char = "┊", -- 与旧 ibl 相同的细实线
			hl = "SnacksIndent",
			scope = {
				enabled = true,
				char = "┊", -- 与缩进线同款，靠颜色区分作用域
				hl = "SnacksIndentScope",
			},
			animate = {
				enabled = false, -- 关闭作用域展开动画，保持轻量
			},
		},
		statuscolumn = {
			enabled = true,
			left = { "mark", "sign", "git" },
			right = { "fold" },
			folds = {
				open = true,
				git_hl = false,
			},
		},
		-- lazygit：终端 Git 可视化界面（按键见 keymaps.lua <leader>gg/gL/gF）
		lazygit = {
			enabled = true,
		},
		-- rename：配合 oil 移动/重命名文件时自动更新引用（见 plugins/configs/oil.lua）
		rename = {
			enabled = true,
		},
		-- bigfile：超大文件自动关闭重特性，避免卡顿
		bigfile = {
			enabled = true,
		},
		-- bufdelete：智能关闭缓冲（处理终端/未保存等）
		bufdelete = {
			enabled = true,
		},
		-- scratch：快速临时草稿缓冲
		scratch = {
			enabled = true,
		},
		-- words：高亮重复出现的词（LspAttach 触发）
		words = {
			enabled = true,
		},
		-- quickfile：`nvim <文件>` 时插件加载前先渲染文件，启动提速
		quickfile = {
			enabled = true,
		},
		-- picker：替代 telescope 的搜索（按键见 keymaps.lua <leader>f*）
		picker = {
			enabled = true,
			layout = {
				-- 自定义 telescope 风格布局：列表左/预览右
				reverse = true,
				layout = {
					box = "horizontal",
					backdrop = false,
					width = 0.8,
					height = 0.9,
					border = "none",
					{
						box = "vertical",
						{ win = "list", title = " Results ", title_pos = "center", border = true },
						{
							win = "input",
							height = 1,
							border = true,
							title = "{title} {live} {flags}",
							title_pos = "center",
						},
					},
					{
						win = "preview",
						title = "{preview:Preview}",
						width = 0.55, -- 预览宽度(对应旧 telescope 的 0.55)
						border = true,
						title_pos = "center",
					},
				},
			},
			file_ignore_patterns = {
				"node_modules/",
				"%.git/",
				"client/node_modules/",
				"__pycache__/",
				"venv/",
				"%.env",
			},
			matcher = {
				frecency = true, -- 常用/最近文件加权排前
			},
			sources = {
				files = { hidden = true }, -- 搜索时显示隐藏文件
				grep = { rg_opts = { "--hidden" } }, -- 全局搜索含隐藏文件
			},
			win = {
				list = { border = "rounded" },
				preview = { border = "rounded" },
			},
			toggles = { hidden = false },
		},
		-- 🌟 启动页 Dashboard（内容与布局来自参照配置）
		-- snacks 会在 UIEnter 后自动判断：无参数启动 + 空缓冲区时自动打开
		dashboard = {
			enabled = true,
			preset = {
				-- pick 选择器：nil=默认，按 fzf-lua → telescope → mini.pick → snacks picker 顺序自动选择
				pick = nil,
				keys = {
					{ icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
					{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
					{
						icon = " ",
						key = "g",
						desc = "Find Text",
						action = ":lua Snacks.dashboard.pick('live_grep')",
					},
					{
						icon = " ",
						key = "r",
						desc = "Recent Files",
						action = ":lua Snacks.dashboard.pick('oldfiles')",
					},
					{
						icon = " ",
						key = "c",
						desc = "Config",
						action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
					},
					{ icon = " ", key = "s", desc = "Restore Session", section = "session" },
					{
						icon = "󰒲 ",
						key = "l",
						desc = "Lazy",
						action = ":Lazy",
						enabled = package.loaded.lazy ~= nil,
					},
					{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
				},
				header = "", -- 动画 Logo 由上方 terminal 段承担，不额外占行
			},
			sections = dashboard_sections,
		},
	})

	-- 强制启用缩进线：snacks 靠一次性事件(BufReadPost)懒加载 indent，
	-- 真实会话时序变化常导致该事件被消耗而模块永不加载(loaded=false)。
	-- 这里直接加载并启用，enable() 有幂等保护，重复调用无害。
	pcall(function()
		require("snacks.indent").enable()
	end)
end
