-- =========================================================================
-- flash.nvim 极速跳转配置（替代 EasyMotion）
-- =========================================================================
return function()
	local flash_status, flash = pcall(require, "flash")
	if not flash_status then
		return
	end

	flash.setup({
		search = {
			multi_window = true,
			forward = true,
			mode = "search",
			incremental = false,
		},
		modes = {
			char = {
				-- 对应你原本的 smartcase (智能大小写匹配)
				jump_labels = true,
			},
		},
	})

	-- 完美的快捷键映射 (这里使用标准的 vim.keymap)
	-- 只要按下 's'，就可以输入你要跳转的目标字符，屏幕会秒级显示跳转标签
	vim.keymap.set({ "n", "x", "o" }, "s", function()
		flash.jump()
	end, { desc = "Flash 跳转" })
	-- 选择当前光标处的 Treesitter 代码块 (比如快速选中整个 if 语句或整个函数)
	vim.keymap.set({ "n", "x", "o" }, "S", function()
		flash.treesitter()
	end, { desc = "Flash 选中代码块" })
end
