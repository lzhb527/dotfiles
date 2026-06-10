-- =============================================================================
-- 1. flash.nvim 配置与快捷键 (降维打击替代 EasyMotion)
-- =============================================================================
-- 对应你原本的 EasyMotion_smartcase 和禁用默认映射，改为极其顺手的现代键位
local flash_status, flash = pcall(require, "flash")
if flash_status then
	flash.setup({
		search = {
			multi_window = true,
			forward = true,
			mode = "search",
			incremental = false,
		},
		modes = {
			char = {
				-- 对应你原本的 smartcase (智能大小写匹配)
				jump_labels = true,
			},
		},
	})

	-- 完美的快捷键映射 (这里使用标准的 vim.keymap)
	-- 只要按下 's'，就可以输入你要跳转的目标字符，屏幕会秒级显示跳转标签
	vim.keymap.set({ "n", "x", "o" }, "s", function()
		flash.jump()
	end, { desc = "Flash 跳转" })
	-- 选择当前光标处的 Treesitter 代码块 (比如快速选中整个 if 语句或整个函数)
	vim.keymap.set({ "n", "x", "o" }, "S", function()
		flash.treesitter()
	end, { desc = "Flash 选中代码块" })
end

-- =============================================================================
-- 2. ToggleTerm 浮动终端 (🌟 完美替代旧的 Floaterm)
-- =============================================================================
local toggleterm_status, toggleterm = pcall(require, "toggleterm")
if toggleterm_status then
	toggleterm.setup({
		size = 20,
		open_mapping = [[<F2>]], -- 🌟 保持并增强你的习惯：在任何模式下按下 F2键都能一键唤出/隐藏
		direction = "float", -- 浮动窗口模式
		close_on_exit = true, -- 🌟 对应你原本的 floaterm_autoclose = 1 (进程退出时自动关闭窗口)
		float_opts = {
			border = "rounded", -- 圆角边框，视觉更现代
		},
	})

	-- 针对终端模式的特殊优化：在终端里按 Esc 键或 F2 就能直接退出输入模式或关闭窗口
	function _G.set_terminal_keymaps()
		local opts = { buffer = 0 }
		vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)
		vim.keymap.set("t", "<F2>", [[<Cmd>ToggleTerm<CR>]], opts)
	end
	vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
end

-- =============================================================================
-- 3. 净化后的 Snacks 状态列配置（彻底干掉冲突的竖线）
-- =============================================================================

-- 🌟 核心修复 1：将原生折叠列强行设为 "0"！
-- 别担心，Snacks 会自己画箭头，设为 0 就能彻底变干净，消灭那条纵向的长绿线。
vim.opt.foldcolumn = "0"

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

local snacks_status, snacks = pcall(require, "snacks")
if snacks_status then
	vim.opt.statuscolumn = [[%!v:lua.Snacks.statuscolumn()]]

	-- 🌟 核心修复 2：彻底置空原生的折叠连接线
	vim.opt.fillchars = {
		foldopen = "", -- 展开时的现代箭头
		foldclose = "", -- 折叠时的现代箭头
		fold = " ", -- 彻底消除原生的纵向连接竖线
		foldsep = " ", -- 彻底消除原生的纵向分隔竖线
	}

	snacks.setup({
		statuscolumn = {
			enabled = true,
			left = { "mark", "sign", "git" }, -- 最左侧：闪电图标（Sign）和书签（Mark）
			right = { "fold" }, -- 右侧：只留 Snacks 的纯净折叠箭头和真正的 Git 状态色块
			folds = {
				open = true, -- 没折叠时也显示小箭头，方便鼠标随时点
				git_hl = false,
			},
		},
	})
end

-- =============================================================================
-- 4. 多光标插件 (vim-visual-multi) 强制高亮修复
-- =============================================================================
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
