-- =========================================================================
-- gitsigns.nvim Git 状态集成与交互控制
-- =========================================================================
return function()
	local status, gitsigns = pcall(require, "gitsigns")
	if not status then
		return
	end

	-- =========================================================================
	-- 🎨 Git 符号栏配色（硬编码，不依赖任何主题插件）
	-- =========================================================================
	local set_hl = vim.api.nvim_set_hl

	set_hl(0, "GitSignsAdd", { fg = "#00ffff", bold = true }) -- 新增（绿）
	set_hl(0, "GitSignsChange", { fg = "#e0af68", bold = true }) -- 修改（蓝/青）
	set_hl(0, "GitSignsDelete", { fg = "#ff0000", bold = true }) -- 删除（红）
	set_hl(0, "GitSignsTopdelete", { fg = "#ff0000", bold = true })
	set_hl(0, "GitSignsChangedelete", { fg = "#2ac3de", bold = true })
	set_hl(0, "GitSignsUntracked", { fg = "#3b4261", bold = true }) -- 未追踪（灰）

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
