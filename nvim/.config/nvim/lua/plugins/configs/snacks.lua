-- =========================================================================
-- snacks.nvim 配置（状态列 + 启动页 Dashboard）
-- =========================================================================
return function()
	-- 🌟 核心修复 1：将原生折叠列强行设为 "0"！
	-- 别担心，Snacks 会自己画箭头，设为 0 就能彻底变干净，消灭那条纵向的长绿线。
	vim.opt.foldcolumn = "0"

	vim.opt.foldmethod = "expr"
	vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	vim.opt.foldlevel = 99
	vim.opt.foldlevelstart = 99

	local snacks_status, snacks = pcall(require, "snacks")
	if not snacks_status then
		return
	end

	vim.opt.statuscolumn = [[%!v:lua.Snacks.statuscolumn()]]

	-- 🌟 核心修复 2：彻底置空原生的折叠连接线
	vim.opt.fillchars = {
		foldopen = "", -- 展开时的现代箭头
		foldclose = "", -- 折叠时的现代箭头
		fold = " ", -- 彻底消除原生的纵向连接竖线
		foldsep = " ", -- 彻底消除原生的纵向分隔竖线
	}

	snacks.setup({
		statuscolumn = {
			enabled = true,
			left = { "mark", "sign", "git" }, -- 最左侧：闪电图标（Sign）和书签（Mark）
			right = { "fold" }, -- 右侧：只留 Snacks 的纯净折叠箭头和真正的 Git 状态色块
			folds = {
				open = true, -- 没折叠时也显示小箭头，方便鼠标随时点
				git_hl = false,
			},
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
				header = [[
                                                                             
               ████ ██████           █████      ██                     
              ███████████             █████                             
              █████████ ███████████████████ ███   ███████████   
             █████████  ███    █████████████ █████ ██████████████   
            █████████ ██████████ █████████ █████ █████ ████ █████   
          ███████████ ███    ███ █████████ █████ █████ ████ █████  
         ██████  █████████████████████ ████ █████ █████ ████ ██████ 
            ]],
			},
			sections = {
				{ section = "header" },
				{ section = "recent_files", icon = "  ", title = "Recent Files", indent = 1, padding = 1 },
				{ section = "keys", indent = 1, padding = 1 },
				{ section = "startup", icon = "" },
			},
		},
	})
end
