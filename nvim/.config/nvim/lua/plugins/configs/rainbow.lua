-- =========================================================================
-- rainbow-delimiters.nvim 现代彩虹括号配置
-- =========================================================================
return function()
	local rb_status, rb = pcall(require, "rainbow-delimiters")
	if not rb_status then
		return
	end

	vim.g.rainbow_delimiters = {
		strategy = {
			[""] = rb.strategy["global"],
		},
		query = {
			[""] = "rainbow-delimiters",
		},
		highlight = {
			"RainbowDelimiterRed",
			"RainbowDelimiterYellow",
			"RainbowDelimiterBlue",
			"RainbowDelimiterOrange",
			"RainbowDelimiterGreen",
		},
	}

	-- 完美同步你原本的 Gruvbox 配色
	local colors = {
		Red = "#fb4934",
		Yellow = "#b8bb26",
		Blue = "#83a598",
		Orange = "#d3869b",
		Green = "#8ec07c",
	}
	for role, color in pairs(colors) do
		vim.api.nvim_set_hl(0, "RainbowDelimiter" .. role, { fg = color })
	end
end
