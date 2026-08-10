-- =========================================================================
-- venv-selector.nvim Python 虚拟环境自动加载
-- =========================================================================
return function()
	local venv_status, venv_selector = pcall(require, "venv-selector")
	if not venv_status then
		return
	end

	venv_selector.setup({
		auto_refresh = true,
		search_workspace = true,
		search_venv_managers = true,
		name = { "venv", ".venv", "env" },
		auto_select = true,
		options = {
			-- 🌟 必须设为 false！否则 venv-selector 会把 vim.notify 覆盖成 notify 模块表，
			-- 与 Noice 的 vim.notify 冲突，打开 Python 文件时会弹窗
			-- "`vim.notify` has been overwritten by another plugin?"
			override_notify = false,
		},
	})

	-- 🌟 按键：一键弹出虚拟环境切换器
	vim.keymap.set("n", "<leader>v", "<cmd>VenvSelect<CR>", { desc = "切换 Python 虚拟环境" })

	vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
		pattern = "python",
		callback = function()
			vim.cmd("silent! VenvSelectCached")
		end,
	})
end
