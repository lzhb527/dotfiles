-- =========================================================================
-- bufferline.nvim 缓冲区标签配置
-- =========================================================================
return function()
	local bufferline_status, bufferline = pcall(require, "bufferline")
	if not bufferline_status then
		return
	end

	-- 🎨 双主题感知的高亮（切换主题时由 ColorScheme 回调重设）
	local function get_highlights()
		local c = require("configs.themes").get()
		return {
			-- 未选中标签的背景：强行隐形，继承主题底色
			fill = {
				bg = { attribute = "bg", highlight = "Normal" },
			},
			background = {
				bg = { attribute = "bg", highlight = "Normal" },
				fg = c.gray, -- 主题标志性灰紫作为未激活文字色
			},

			-- 当前选中的标签：微微调亮，拉开层次，文字继承主题纯正的高亮色
			buffer_selected = {
				bg = c.bufferline_sel_bg, -- 选中行/状态栏略亮炭黑
				fg = c.cyan, -- 标志性青蓝，一眼看出当前在写哪个文件
				bold = true,
			},

			-- 侧边分割线：克制低调
			separator = {
				fg = c.bufferline_dim_bg,
				bg = { attribute = "bg", highlight = "Normal" },
			},
			separator_selected = {
				fg = c.bufferline_dim_bg,
				bg = c.bufferline_dim_bg,
			},

			-- 提示/报错图标在顶栏的颜色适配
			info_diagnostic_selected = { fg = c.cyan, bg = c.bufferline_dim_bg, bold = true },
			warning_diagnostic_selected = { fg = c.yellow, bg = c.bufferline_dim_bg, bold = true },
			error_diagnostic_selected = { fg = c.red, bg = c.bufferline_dim_bg, bold = true },
		}
	end

	local function setup_bufferline()
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

				-- 基础行为
				diagnostics = "nvim_lsp", -- 顶栏直接显示对应文件的 LSP 报错状态
				always_show_bufferline = true,
			},

			-- 🎨 主题感知的色彩救赎（消除割裂感的灵魂）
			highlights = get_highlights(),
		})
	end

	setup_bufferline()

	-- 切换主题时重设 bufferline 高亮
	vim.api.nvim_create_autocmd("ColorScheme", {
		callback = function()
			setup_bufferline()
		end,
	})
end
