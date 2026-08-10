-- =========================================================================
-- toggleterm.nvim 浮动终端配置（替代旧的 Floaterm）
-- =========================================================================
return function()
	local toggleterm_status, toggleterm = pcall(require, "toggleterm")
	if not toggleterm_status then
		return
	end

	toggleterm.setup({
		size = 20,
		open_mapping = [[<F2>]], -- 🌟 保持并增强你的习惯：在任何模式下按下 F2键都能一键唤出/隐藏
		direction = "float", -- 浮动窗口模式
		close_on_exit = true, -- 🌟 对应你原本的 floaterm_autoclose = 1 (进程退出时自动关闭窗口)
		float_opts = {
			border = "rounded", -- 圆角边框，视觉更现代
		},
	})

	-- 针对终端模式的特殊优化：在终端里按 Esc 键或 F2 就能直接退出输入模式或关闭窗口
	function _G.set_terminal_keymaps()
		local opts = { buffer = 0 }
		vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)
		vim.keymap.set("t", "<F2>", [[<Cmd>ToggleTerm<CR>]], opts)
	end
	vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
end
