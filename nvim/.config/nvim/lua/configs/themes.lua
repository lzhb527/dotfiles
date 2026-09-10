-- =========================================================================
-- 双主题共享色板：tokyonight-night / catppuccin-mocha
-- 供 theme.lua、bufferline、rainbow、gitsigns、dap 等统一取色，
-- 实现 <leader>uT 一键切换时所有硬编码色同步跟随。
-- =========================================================================
local M = {}

M.tokyonight = {
	comment = "#9aa5ce", -- 注释（亮）
	winseparator = "#565f89",
	visual_bg = "#3b4261",
	float_border = "#7dcfff",
	indent = "#565f89",
	indent_scope = "#2ac3de",
	reference_bg = "#292e42",
	red = "#f7768e",
	green = "#9ece6a",
	yellow = "#e0af68",
	blue = "#7aa2f7",
	cyan = "#7dcfff",
	orange = "#ff9e64",
	magenta = "#bb9af7",
	gray = "#565f89",
	bufferline_sel_bg = "#292e42",
	bufferline_dim_bg = "#1f2335",
}

M.catppuccin = {
	comment = "#a6adc8", -- 注释（亮）
	winseparator = "#6c7086",
	visual_bg = "#313244",
	float_border = "#94e2d5",
	indent = "#6c7086",
	indent_scope = "#94e2d5",
	reference_bg = "#313244",
	red = "#f38ba8",
	green = "#a6e3a1",
	yellow = "#f9e2af",
	blue = "#89b4fa",
	cyan = "#94e2d5",
	orange = "#fab387",
	magenta = "#f5c2e7",
	gray = "#6c7086",
	bufferline_sel_bg = "#313244",
	bufferline_dim_bg = "#181825",
}

--- 按当前主题返回色板（ColorScheme 事件触发时 vim.g.colors_name 已就绪）
function M.get()
	local name = vim.g.colors_name or ""
	return name:match("^catppuccin") and M.catppuccin or M.tokyonight
end

return M
