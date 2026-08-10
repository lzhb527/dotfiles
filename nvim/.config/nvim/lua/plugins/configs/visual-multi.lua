-- =========================================================================
-- vim-visual-multi 多光标配置（含强制高亮修复）
-- =========================================================================
return function()
	-- 快捷键映射：Ctrl+M 快速选中当前单词
	vim.g.VM_maps = {
		["Find Under"] = "<C-m>",
	}

	-- 提前禁用插件自带的默认暗淡配色逻辑
	vim.g.VM_theme_set_by_colorscheme = 0
	vim.g.VM_default_mappings = 1

	-- 核心修复函数：使用最高优先级的 nvim_set_hl 强制注入亮眼配色
	local function apply_vm_highlights()
		-- 选中的所有单词：强制改为极其醒目的「亮黄色背景，纯黑文本」
		vim.api.nvim_set_hl(0, "VM_Extend", { bg = "#FFD700", fg = "#000000", force = true })
		-- 闪烁的多个虚拟光标：强制改为「鲜艳的红色背景，纯白文本」
		vim.api.nvim_set_hl(0, "VM_Cursor", { bg = "#FF5555", fg = "#FFFFFF", force = true })
	end

	-- 监听主题切换，确保每次加载或切换皮肤时高亮都不会被重置
	vim.api.nvim_create_autocmd("ColorScheme", {
		pattern = "*",
		callback = apply_vm_highlights,
	})

	-- 立即在初始化时执行一次
	apply_vm_highlights()
end
