-- =========================================================================
-- snacks.nvim 净化后的状态列配置（彻底干掉冲突的竖线）
-- =========================================================================
return function()
	-- 🌟 核心修复 1：将原生折叠列强行设为 "0"！
	-- 别担心，Snacks 会自己画箭头，设为 0 就能彻底变干净，消灭那条纵向的长绿线。
	vim.opt.foldcolumn = "0"

	vim.opt.foldmethod = "expr"
	vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	vim.opt.foldlevel = 99
	vim.opt.foldlevelstart = 99

	local snacks_status, snacks = pcall(require, "snacks")
	if not snacks_status then
		return
	end

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
