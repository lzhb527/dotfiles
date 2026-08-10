-- =========================================================================
-- trouble.nvim 现代代码诊断与结果列表可视化 (v3)
-- =========================================================================
return {
	-- 🌟 新版 v3 核心：指定默认行为和外观
	auto_close = false, -- 当列表空了之后，是否自动关闭 Trouble 面板
	auto_open = false, -- 当有代码报错时，是否自动弹窗（通常保持 false 避免干扰写代码）
	restore = true, -- 当重新打开面板时，恢复上一次的折叠状态
	follow = true, -- 列表光标自动跟随主窗口光标所在的代码位置
	indent_guides = true, -- 在报错树状图左侧画出漂亮的层级对齐虚线
	max_items = 200, -- 面板内最大显示条目数

	-- 视觉图标配置（保持与主流图标对齐）
	icons = {
		indent = {
			top = "│ ",
			middle = "├─ ",
			last = "└─ ",
			fold_open = " ",
			fold_closed = " ",
			ws = "  ",
		},
	},

	-- 节制多余视觉：多窗口分屏时，确保边界线整洁
	win = {
		wo = {
			winhighlight = "Normal:TroubleNormal,SignColumn:TroubleSignColumn",
		},
	},
}
