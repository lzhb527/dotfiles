-- =========================================================================
-- nvim-surround 键位重绑
-- Flash 占用了 s/S（含 operator-pending），故把包围操作改到 gz 前缀，
-- 并提供一套 <leader>z 别名（同一功能，供空格菜单「文件编辑」使用）：
--   gza{motion}{符号} / <leader>za{motion}{符号}  加包围（如 gzaiw"）
--   gzc{目标}{替换}   / <leader>zc{目标}{替换}     改包围（如 gzc"'）
--   gzd{符号}         / <leader>zd{符号}           删包围（如 gzd"）
--   可视 gza          / 可视 <leader>za            选区加包围
-- 插入模式保持默认 <C-g>s / <C-g>S（不与 Flash 冲突）
-- 注意：gz / <leader>z 本身不单独映射，只作前缀，避免加包围等待 timeoutlen。
-- =========================================================================
return function()
	-- gz 前缀（原有）
	vim.keymap.set("n", "gza", "<Plug>(nvim-surround-normal)", { desc = "加包围 gza{motion}{符号}" })
	vim.keymap.set("n", "gzc", "<Plug>(nvim-surround-change)", { desc = "改包围 gzc{目标}{替换}" })
	vim.keymap.set("n", "gzd", "<Plug>(nvim-surround-delete)", { desc = "删包围 gzd{符号}" })
	vim.keymap.set("x", "gza", "<Plug>(nvim-surround-visual)", { desc = "可视选区加包围" })

	-- <leader>z 别名（同一功能，供空格菜单「文件编辑」使用）
	vim.keymap.set("n", "<leader>za", "<Plug>(nvim-surround-normal)", { desc = "加包围 <leader>za{motion}{符号}" })
	vim.keymap.set("n", "<leader>zc", "<Plug>(nvim-surround-change)", { desc = "改包围 <leader>zc{目标}{替换}" })
	vim.keymap.set("n", "<leader>zd", "<Plug>(nvim-surround-delete)", { desc = "删包围 <leader>zd{符号}" })
	vim.keymap.set("x", "<leader>za", "<Plug>(nvim-surround-visual)", { desc = "可视选区加包围" })
end
