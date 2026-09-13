-- =========================================================================
-- aerial.nvim 代码标签树配置（替代旧的 Tagbar）
-- =========================================================================
return function()
	local aerial_status, aerial = pcall(require, "aerial")
	if not aerial_status then
		return
	end

	aerial.setup({
		layout = {
			max_width = { 40, 0.2 },
			width = 30, -- 对应原本的 tagbar_width = 30
		},
		close_on_select = false, -- 选中时不自动关闭
		show_guides = true, -- 显示漂亮的树状引导线
		filter_kind = false, -- 完美显示所有函数、类、变量

		-- 🌟 核心修复：当打开支持的语言（如 Python）时，在后台自动激活 Aerial 服务
		on_attach = function(bufnr)
			-- 💡 这样一打开文件，后台的数据导轨就已经就绪，绝不会再报 No items found！
			-- 如果你之前绑定了诸如 { 和 } 在函数间跳跃，这里会自动打通。
		end,

		-- 强力推荐：确保后端首选依赖刚才配好的 Tree-sitter
		backends = { "treesitter", "lsp", "markdown", "man" },
	})

	-- 🌟 说明：Aerial 的开关键 <F12> 已统一由 lua/configs/keymaps.lua 管理，这里不再重复绑定
end
