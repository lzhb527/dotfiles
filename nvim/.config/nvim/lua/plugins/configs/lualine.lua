-- =========================================================================
-- lualine.nvim 状态栏配置
-- =========================================================================
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

return {
	options = {
		theme = "auto",
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		-- 🌟 同步修正：将过时的 NvimTree 更改为现代的 neo-tree
		disabled_filetypes = { "neo-tree", "snacks_dashboard" },
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
}
