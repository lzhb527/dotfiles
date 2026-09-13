-- =========================================================================
-- markview.nvim Markdown 渲染增强配置
-- =========================================================================
return function()
	local ok, markview = pcall(require, "markview")
	if not ok then
		return
	end

	local presets = require("markview.presets")

	markview.setup({
		-- =================================================================
		-- 预览/渲染行为
		-- =================================================================
		preview = {
			enable = true,
			enable_hybrid_mode = true, -- 保持可编辑的同时渲染
			debounce = 150,
			map_gx = true, -- gx 打开链接
			-- 只在阅读模式的模式里渲染，避免编辑时闪烁
			modes = { "n", "no", "c" },
		},

		-- =================================================================
		-- Markdown 渲染器细节
		-- =================================================================
		markdown = {
			-- 任务清单：Nerd Font 勾选框 + 完成项删除线
			checkboxes = presets.checkboxes.nerd,

			-- 代码块：统一整块背景（可读性更好），窄窗口也保留
			code_blocks = {
				enable = true,
				min_width = 50, -- 默认 60，窄屏更友好
				pad_amount = 2,
				sign = true, -- 语言角标
			},

			-- 引用块：默认已带关键字图标（TODO/INFO/SUCCESS 等），保持
			block_quotes = {
				enable = true,
				wrap = true, -- 长内容自动换行
			},

			-- 列表：- 用实心点，层级清晰
			list_items = {
				enable = true,
				wrap = true,
				marker_minus = { text = "●", add_padding = true, conceal_on_checkboxes = true },
				marker_plus = { text = "◈", add_padding = true, conceal_on_checkboxes = true },
				marker_star = { text = "◇", add_padding = true, conceal_on_checkboxes = true },
			},

			-- 表格：默认圆角边框已好看，保持
			tables = {
				enable = true,
			},

			-- 标题：默认图标样式已不错，保持
			headings = {
				enable = true,
			},

			-- 分隔线：默认渐变色，保持
			horizontal_rules = {
				enable = true,
			},
		},
	})
end
