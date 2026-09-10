-- =========================================================================
-- blink.cmp 补全核心配置（替代 nvim-cmp + LuaSnip 全家桶）
-- 使用内置 vim.snippet 引擎 + friendly-snippets，无需 LuaSnip
-- =========================================================================
return function()
	local blink_status, blink = pcall(require, "blink.cmp")
	if not blink_status then
		return
	end

	blink.setup({
		-- =========================================================================
		-- 1. 按键映射：保持与旧 nvim-cmp 完全一致的肌肉记忆
		--    Tab=选择下一个 / S-Tab=选择上一个 / Enter=确认 / Esc=收起 / C-Space=呼出
		-- =========================================================================
		keymap = {
			preset = "default", -- 附带 C-Space、C-e、方向键、C-b/C-f 滚动文档等基础键
			["<TAB>"] = { "select_next", "snippet_forward", "fallback" },
			["<S-TAB>"] = { "select_prev", "snippet_backward", "fallback" },
			["<CR>"] = { "accept", "fallback" },
			["<ESC>"] = { "hide", "fallback" },
		},

		-- =========================================================================
		-- 2. 补全窗口样式（对齐旧配置的圆角边框）
		-- =========================================================================
		completion = {
			list = {
				selection = {
					auto_insert = false, -- 与旧 nvim-cmp 一致：只选中不自动插入，Enter 才确认
				},
			},
			menu = {
				border = "rounded",
			},
			documentation = {
				auto_show = true, -- 选中即显示文档浮窗（同旧行为）
				auto_show_delay_ms = 300,
				window = { border = "rounded" },
			},
			accept = {
				auto_brackets = {
					-- 自动补全函数括号（如补全 print 后自动补 ()），等效旧 autopairs 联动
					enabled = true,
				},
			},
		},

		-- =========================================================================
		-- 3. 补全源：LSP / 代码片段 / 路径 / 缓冲区
		-- =========================================================================
		sources = {
			default = { "lsp", "snippets", "path", "buffer" },
			providers = {
				lsp = { score_offset = 0 }, -- LSP 永远最高优先级
				snippets = {
					score_offset = -1,
					opts = {
						friendly_snippets = true, -- 自动加载 friendly-snippets 库
						-- 复合文件类型继承：yaml.ansible 同时加载 yaml 与 ansible 的片段
						extended_filetypes = { ["yaml.ansible"] = { "yaml", "ansible" } },
					},
				},
				path = { score_offset = 2 },
				buffer = { score_offset = -5 },
			},
		},
	})
end
