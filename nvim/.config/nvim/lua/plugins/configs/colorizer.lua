-- =========================================================================
-- nvim-colorizer.lua 颜色高亮配置（彻底修复 expected table, got string 报错）
-- =========================================================================
return {
	-- 🌟 修正：将裸字符串改为以文件类型（Filetype）为 Key 的 Table 格式
	["*"] = {
		css = true,
		html = true,
	},
	css = { rgb_fn = true },
	html = { names = true },
}
