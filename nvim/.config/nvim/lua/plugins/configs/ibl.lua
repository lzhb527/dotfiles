-- =========================================================================
-- indent-blankline.nvim 现代缩进线配置
-- =========================================================================
return function()
	local ibl_status, ibl = pcall(require, "ibl")
	if not ibl_status then
		return
	end

	-- =========================================================================
	-- 🎨 设定缩进线颜色组（完美适配 Tokyo Night 霓虹色调）
	-- =========================================================================
	local set_hl = vim.api.nvim_set_hl

	-- 1. 普通缩进线的颜色：设为非常低调的暗灰色，若隐若现不干扰视线
	set_hl(0, "IblIndent", { fg = "#292e42", nocombine = true })

	-- 2. 🌟 当前函数/代码块的作用域高亮颜色（核心修改项）
	-- 这里推荐使用 Tokyo Night 标志性的青色 (#2ac3de) 或霓虹蓝 (#7aa2f7)
	set_hl(0, "IblScope", { fg = "#2ac3de", nocombine = true })

	ibl.setup({
		indent = {
			char = "┊", -- 经典的细实线
			highlight = "IblIndent", -- 指定普通缩进线的颜色组
		},
		scope = {
			enabled = true, -- 动态高亮当前光标所在的代码块
			show_start = true, -- 是否在函数开头画一根横线
			show_end = true,
			highlight = "IblScope", -- 指定当前活动作用域的颜色组
		},
		exclude = {
			filetypes = {
				"snacks_dashboard",
				"alpha",
				"neo-tree", -- 🌟 同步修正：防止缩进线破坏 Neo-tree 侧边栏的树状视觉效果
				"lazy",
				"mason",
				"terminal",
				"help",
				"notify",
				"toggleterm",
			},
		},
	})
end
