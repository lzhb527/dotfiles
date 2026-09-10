-- =========================================================================
-- gitsigns.nvim Git 状态集成与交互控制
-- =========================================================================
return function()
	local status, gitsigns = pcall(require, "gitsigns")
	if not status then
		return
	end

	-- =========================================================================
	-- 🎨 Git 符号栏配色（双主题感知，切换主题时自动跟随）
	-- =========================================================================
	local set_hl = vim.api.nvim_set_hl

	local function setup_git_signs_colors()
		local c = require("configs.themes").get()
		set_hl(0, "GitSignsAdd", { fg = c.green, bold = true }) -- 新增（绿）
		set_hl(0, "GitSignsChange", { fg = c.yellow, bold = true }) -- 修改（黄）
		set_hl(0, "GitSignsDelete", { fg = c.red, bold = true }) -- 删除（红）
		set_hl(0, "GitSignsTopdelete", { fg = c.red, bold = true })
		set_hl(0, "GitSignsChangedelete", { fg = c.cyan, bold = true })
		set_hl(0, "GitSignsUntracked", { fg = c.gray, bold = true }) -- 未追踪（灰）
	end

	setup_git_signs_colors()
	vim.api.nvim_create_autocmd("ColorScheme", {
		callback = setup_git_signs_colors,
	})

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
end
