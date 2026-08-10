-- =========================================================================
-- bufferline.nvim 缓冲区标签配置
-- =========================================================================
return function()
	local bufferline_status, bufferline = pcall(require, "bufferline")
	if not bufferline_status then
		return
	end

	bufferline.setup({
		options = {
			mode = "buffers", -- 管理缓冲区
			style_preset = bufferline.style_preset.minimal, -- 🌟 极简预设：去掉刺眼的粗边框，符合老派审美
			numbers = "none", -- 隐藏没用的数字序号
			close_command = "bdelete! %d", -- 联动右键/关闭命令
			right_mouse_command = "bdelete! %d",

			-- 视觉增强
			indicator = {
				style = "underline", -- 当前选中的标签下方显示一条精致的下划线
			},
			buffer_close_icon = "󰅖",
			modified_icon = "●",
			close_icon = "",
			left_trunc_marker = "",
			right_trunc_marker = "",

			-- 完美桥接你的 Neo-tree 文件树，让左侧自动留出空白，视觉极度舒适
			offsets = {
				{
					filetype = "neo-tree",
					text = "  FILE EXPLORER",
					text_align = "center",
					separator = true,
				},
			},

			-- 基础行为
			diagnostics = "nvim_lsp", -- 顶栏直接显示对应文件的 LSP 报错状态
			always_show_bufferline = true,
		},

		-- =========================================================================
		-- 🎨 Molokai 专属色彩救赎 (消除割裂感的灵魂)
		-- =========================================================================
		highlights = {
			-- 未选中标签的背景：强行隐形，使用 Molokai 经典的深炭黑底色
			fill = {
				bg = { attribute = "bg", highlight = "Normal" },
			},
			background = {
				bg = { attribute = "bg", highlight = "Normal" },
				fg = "#75715E", -- 使用 Molokai 标志性的复古哑光灰作为未激活文字色
			},

			-- 当前选中的标签：微微调亮，拉开层次，文字继承 Molokai 纯正的青绿高亮
			buffer_selected = {
				bg = "#161616", -- 经典的 Molokai 选中行/状态栏略亮炭黑
				fg = "#66D9EF", -- 标志性冰冷青绿，一眼看出当前在写哪个文件
				bold = true,
			},

			-- 侧边分割线：克制低调
			separator = {
				fg = "#232526",
				bg = { attribute = "bg", highlight = "Normal" },
			},
			separator_selected = {
				fg = "#232526",
				bg = "#232526",
			},

			-- 提示/报错图标在顶栏的颜色适配
			info_diagnostic_selected = { fg = "#66D9EF", bg = "#232526", bold = true },
			warning_diagnostic_selected = { fg = "#FD971F", bg = "#232526", bold = true }, -- 橙黄
			error_diagnostic_selected = { fg = "#F92672", bg = "#232526", bold = true }, -- 霓虹粉红
		},
	})
end
