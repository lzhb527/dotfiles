-- =========================================================================
-- nvim-colorizer.lua 颜色高亮配置（新版 fork 的 options 结构化格式）
-- =========================================================================
return {
	filetypes = { "*" }, -- 对所有文件类型生效（含纯文本、Markdown 等非代码文件）
	options = {
		parsers = {
			css = true, -- 预设：names + hex + rgb + hsl + oklch + css_var
			css_fn = true, -- 预设：rgb() / hsl() / oklch() 函数形式
		},
		display = {
			-- 默认 true：接管 LSP 颜色高亮并自动禁用内置 document_color，避免重复
		},
	},
}
