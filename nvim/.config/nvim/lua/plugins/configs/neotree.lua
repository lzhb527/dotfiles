-- =========================================================================
-- neo-tree.nvim 文件浏览器配置
-- =========================================================================
return {
	close_if_last_window = false,
	popup_border_style = "rounded",
	enable_git_status = true,
	enable_diagnostics = true,

	-- =========================================================================
	-- 🌟 完美拆离合并：Neo-tree 顶部的 File / Bufs / Git 标签页切换栏
	-- =========================================================================
	source_selector = {
		winbar = true, -- 在文件树顶部开启标签页栏
		statusline = false, -- 关闭底部状态栏的显示
		show_scrolled_by = false, -- 隐藏多余的滚动提示
		sources = { -- 显式定义并美化显示的三个标签页源
			{ source = "filesystem", display_name = "  File " },
			{ source = "buffers", display_name = "  Bufs " },
			{ source = "git_status", display_name = "  Git " },
		},
	},

	-- =========================================================================
	-- 核心交互行为控制
	-- =========================================================================
	window = {
		position = "left",
		width = 30, -- 固定侧边栏物理宽度为 30
		mappings = {

			-- 💡 极客技巧：当光标停在顶部的 File/Bufs/Git 标签栏上或普通目录下时，
			-- 按下键盘的 < 和 > 键（也就是 Shift+, 和 Shift+.）就可以在三个标签页之间无感来回切换！
			["<"] = "prev_source",
			[">"] = "next_source",

			-- 🌟 完美修复：普通目录状态下交由底层原生按键处理，从而彻底消除报错警告
			["<C-j>"] = "none",
			["<C-k>"] = "none",
		},
	},

	filesystem = {
		-- 🌟 搜索框高级联动：只有当你主动按 f 键唤出搜索框并打完字后，
		-- 按 Ctrl+j / Ctrl+k 才能在输入框里直接控制下方文件树的光标跳跃！
		fuzzy_finder_mappings = {
			["<C-j>"] = "move_cursor_down",
			["<C-k>"] = "move_cursor_up",
		},
		bind_to_cwd = true,
		use_libuv_file_watcher = true,
		filtered_items = {
			hide_dotfiles = false, -- 让 .gitignore 等隐藏文件默认直接可见
			hide_gitignored = true, -- 自动将 git 忽略的文件夹置灰，保持视觉绝对干净
		},
		follow_current_file = {
			enabled = true, -- 智能追踪：主窗口切到哪，左侧文件树自动跨目录高亮到哪
		},
	},
}
