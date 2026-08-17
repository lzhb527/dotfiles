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

-- 状态栏主体背景统一为编辑器底色 #1a1b26（两种主题通用）
local function apply_base_bg(theme)
	local modes = { "normal", "insert", "replace", "visual", "command", "terminal" }
	for _, mode in ipairs(modes) do
		if theme[mode] and theme[mode].c then
			theme[mode].c.bg = "#1a1b26"
		end
	end
	if theme.inactive then
		for _, part in ipairs({ "a", "b", "c" }) do
			if theme.inactive[part] then
				theme.inactive[part].bg = "#1a1b26"
			end
		end
	end
	return theme
end

-- 按当前主题返回 lualine 主题（tokyonight 自带官方 lualine 主题，catppuccin 用官方工具函数）
local function get_theme()
	local theme
	if (vim.g.colors_name or ""):match("^catppuccin") then
		theme = require("catppuccin.utils.lualine")()
	else
		theme = require("lualine.themes.tokyonight-night")
	end
	return apply_base_bg(theme)
end

local function setup_lualine()
	require("lualine").setup({
		options = {
			theme = get_theme(),
			component_separators = { left = "", right = "" },
			section_separators = { left = "", right = "" },
			-- 🌟 文件浏览器改为 snacks.explorer 后无需再屏蔽 neo-tree
			disabled_filetypes = { "snacks_dashboard" },
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

return function()
	setup_lualine()

	-- 切换主题时同步 lualine（lualine 支持重复 setup，重设后应用当前主题色）
	vim.api.nvim_create_autocmd("ColorScheme", {
		callback = setup_lualine,
	})
end
