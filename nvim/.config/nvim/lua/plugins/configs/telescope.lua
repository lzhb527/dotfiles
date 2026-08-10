-- =========================================================================
-- telescope.nvim 搜索配置（全面替代 FZF 环境变量）
-- =========================================================================
return function()
	local telescope_status, telescope = pcall(require, "telescope")
	if not telescope_status then
		return
	end

	telescope.setup({
		defaults = {
			layout_strategy = "horizontal",
			layout_config = {
				horizontal = { preview_width = 0.55 },
			},
			sorting_strategy = "ascending", -- 让最新搜到的结果排在最上面
			border = true,
			file_ignore_patterns = {
				"node_modules/",
				"%.git/",
				"client/node_modules/",
				"__pycache__/",
				"venv/",
				"%.env",
			},
		},
	})

	-- 🌟 快捷键已统一由 plugins/init.lua 的 spec keys 管理（ff/fg/fb），这里不再重复绑定
end
