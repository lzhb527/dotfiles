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

	local function set_rainbow_colors()
		local c = require("configs.themes").get()
		-- 完美同步当前主题配色
		local colors = {
			Red = c.red,
			Yellow = c.yellow,
			Blue = c.blue,
			Orange = c.orange,
			Green = c.green,
		}
		for role, color in pairs(colors) do
			vim.api.nvim_set_hl(0, "RainbowDelimiter" .. role, { fg = color })
		end
	end

	set_rainbow_colors()

	-- 切换主题时同步括号颜色
	vim.api.nvim_create_autocmd("ColorScheme", {
		callback = set_rainbow_colors,
	})
end
