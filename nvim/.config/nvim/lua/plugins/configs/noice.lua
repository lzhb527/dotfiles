-- =========================================================================
-- noice.nvim 命令行与搜索栏重构配置
-- =========================================================================
return function()
	local status, noice = pcall(require, "noice")
	if not status then
		return
	end

	-- 🌟 核心修复：在 noice 启动前，强行为依赖的 notify 插件兜底指定背景色
	-- 这样在启用透明终端或 Tokyo Night 主题时，绝对不会再触发黄色警告弹窗。
	pcall(function()
		require("notify").setup({
			background_colour = "#1a1b26", -- 精准对齐 Tokyo Night 官方暗底色
		})
	end)

	noice.setup({
		presets = {
			bottom_search = true, -- 底部搜索栏：使 / 和 ? 搜索窗口停靠在底部，更符合原生习惯
			command_palette = true, -- 命令面板：让 : 命令行变为屏幕中央的悬浮面板（类似全局搜索）
			long_message_to_split = true, -- 长消息分屏：当报错或提示文本行数过长时，自动送入分屏而不阻塞屏幕
			lsp_doc_border = true, -- 文档边框：强制为 LSP Hover（如 K 键提示）的文档窗口添加精美边框
		},

		-- =========================================================================
		-- LSP 深度整合设置 (LSP Integration)
		-- =========================================================================
		lsp = {
			override = {
				-- 覆盖 Neovim 默认的 Markdown 转换与样式渲染，改用 Noice 视觉引擎
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
			},

			-- 关闭 noice 对诊断（报错信息）的接管与渲染
			diagnostics = {
				enabled = false,
			},

			-- 控制签名帮助（函数参数弹窗行为）
			signature = {
				enabled = false,
				opts = {
					-- 强制底层 Markdown 渲染器不渲染任何后续文档行，只留 1 行核心函数名和参数！
					size = { max_height = 1 },
					win_options = {
						wrap = false, -- 严防死守，不让它换行扩展
					},
				},
			},
		},

		-- =========================================================================
		-- 消息路由与过滤规则 (Routes)
		-- =========================================================================
		routes = {
			{
				-- 过滤无用杂音：静音文件保存（如 :w）时底部频繁出现的 "written" 提示
				filter = {
					event = "msg_show",
					find = "written",
					kind = "confirm", -- 拦截 confirm 类型，即 press-enter
				},
				opts = { skip = true }, -- skip = true 代表直接拦截并丢弃该消息
			},
		},
	})
end
