-- =========================================================================
-- dashboard-nvim 启动页配置
-- =========================================================================
return {
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
}
