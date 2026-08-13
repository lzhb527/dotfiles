local map = vim.keymap.set

-- =============================================================================
-- 1. 基础全局快捷键 (不带 Leader 键的直达高频映射)
-- =============================================================================

-- 基础工具开关
local function snacks_explorer_toggle()
	require("snacks").explorer.open({
		layout = "sidebar", -- 侧边栏布局（替代 neo-tree 的左侧停靠）
		git_status = true, -- 文件树显示 Git 状态
		diagnostics = true, -- 显示诊断符号
		hidden = true, -- 显示隐藏文件（对应 neo-tree hide_dotfiles = false）
		follow_file = true, -- 智能追踪当前文件（对应 neo-tree follow_current_file）
		toggles = { hidden = false }, -- 不显示 hidden toggle 的 "h" 徽标
	})
end

map("n", "<F1>", "<cmd>set nu! rnu!<CR>", { noremap = true, silent = true, desc = "切换行号显示" })
map("n", "<C-n>", snacks_explorer_toggle, { noremap = true, silent = true, desc = "切换文件浏览器" })
map("n", "<F12>", "<cmd>AerialToggle! right<CR>", { noremap = true, silent = true, desc = "切换代码结构树" })

-- 极速无感保存 (Ctrl + S)
map("i", "<C-s>", "<Esc><cmd>w<CR>a", { desc = "插入模式快速保存" })
map("v", "<C-s>", "<Esc><cmd>w<CR>gv", { desc = "可视模式快速保存" })
map("n", "<C-s>", "<cmd>w<CR>", { desc = "普通模式快速保存" })

-- Bufferline 标签页极速无感切换
map("n", "<C-Tab>", "<cmd>BufferLineCycleNext<CR>", { silent = true, desc = "下一个标签页" })
map("n", "<C-S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { silent = true, desc = "上一个标签页" })

-- 代码检查诊断跳转 (规避 s 键以防与 Flash.nvim 冲突)
map("n", "[d", vim.diagnostic.goto_prev, { silent = true, desc = "上一个诊断" })
map("n", "]d", vim.diagnostic.goto_next, { silent = true, desc = "下一个诊断" })
map("n", "[e", vim.diagnostic.goto_prev, { silent = true, desc = "上一个错误" })
map("n", "]e", vim.diagnostic.goto_next, { silent = true, desc = "下一个错误" })

-- 自动化高级异步无感格式化 (整合 Conform / LSP)
local function smart_format()
	local conform_ok, conform = pcall(require, "conform")
	if conform_ok then
		conform.format({ async = true, lsp_fallback = true })
	else
		vim.lsp.buf.format({ async = true })
	end
end
map("n", "<F6>", smart_format, { desc = "智能异步格式化" })
map("n", "<leader>fm", smart_format, { desc = "智能异步格式化" })

-- =============================================================================
-- 2. 独立插件核心配置 (Flash.nvim 极速跳转)
-- 说明：Flash 的 setup 与 s / S 按键已统一收敛到 lua/plugins/configs/flash.lua
-- =============================================================================

-- =============================================================================
-- 3. Snacks.terminal 终端管理基础键 (功能键直达)
-- 说明：toggleterm 已迁移至 snacks.terminal。F2 浮动终端 / F9 底部终端
-- 通过 count 区分身份，避免同一 cwd 的终端被共用。
-- =============================================================================
local function snacks_term_toggle(position, count)
	require("snacks").terminal.toggle(nil, {
		win = {
			position = position, -- 位置必须放 win 子表，top-level position 会被忽略
			border = position == "float" and "rounded" or "none", -- 浮动终端圆角边框
		},
		count = count,
		auto_close = true, -- 进程退出自动关闭（对应 toggleterm.close_on_exit）
	})
end

-- 收起当前光标所在终端（终端模式内用）
local function snacks_term_hide()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
	vim.schedule(function()
		local cur = vim.api.nvim_get_current_buf()
		for _, t in ipairs(require("snacks").terminal.list()) do
			if t.buf == cur then
				t:hide()
				return
			end
		end
	end)
end

map("n", "<F2>", function() snacks_term_toggle("float", 1) end, { silent = true, desc = "切换浮动终端" })
map("n", "<F9>", function() snacks_term_toggle("bottom", 2) end, { silent = true, desc = "切换底部终端" })
map("n", "<F10>", "<cmd>close<CR>", { silent = true, desc = "关闭当前终端窗口" })

map("t", "<F2>", snacks_term_hide, { silent = true, desc = "收起终端回到代码" })
map("t", "<F9>", snacks_term_hide, { silent = true, desc = "收起底部终端" })
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "双击Esc退出终端输入模式" })

-- =============================================================================
-- 4. Which-Key 现代菜单一站式映射 (全面适配 v3 规范)
-- 说明：which-key 的 setup 已统一收敛到 lua/plugins/configs/whichkey.lua
-- =============================================================================
local ok, wk = pcall(require, "which-key")
if not ok then
	return
end

-- 普通模式 (Normal Mode) 菜单
wk.add({
	mode = "n",
	-- 主菜单定义
	{ "<leader>", group = "主菜单" },
	{ "<leader>?", "<cmd>WhichKey<cr>", desc = "快捷键(help file)" },
	{ "<leader>S", "<cmd>w!<CR>", desc = "强行保存当前文件", hidden = true },

	-- 搜索组 (snacks.picker)
	{ "<leader>f", group = "搜索查找 (Find)" },
	{ "<leader>ff", function() require("snacks").picker.files() end, desc = "查找文件名称" },
	{ "<leader>fg", function() require("snacks").picker.grep() end, desc = "全局文本搜索" },
	{ "<leader>fb", function() require("snacks").picker.buffers() end, desc = "查找活动缓冲区" },
	{ "<leader>fh", function() require("snacks").picker.recent() end, desc = "历史打开记录" },
	{ "<leader>fc", function() require("snacks").picker.git_log() end, desc = "Git 提交历史" },
	{ "<leader>fr", function() require("snacks").picker.grep_word() end, desc = "搜索光标下单词" },

	-- 代码行为组 (LSP)
	{ "<leader>c", group = "代码行为(LSP CODE)" },
	{ "<leader>cr", vim.lsp.buf.rename, desc = "重命名变量/符号" },
	{ "<leader>ce", vim.diagnostic.open_float, desc = "弹窗查看诊断信息" },
	{ "<leader>cd", vim.lsp.buf.definition, desc = "跳转至定义" },
	{ "<leader>ci", vim.lsp.buf.implementation, desc = "跳转至接口实现" },
	{ "<leader>cf", vim.lsp.buf.references, desc = "查找全局引用" },
	{ "<leader>ck", vim.lsp.buf.hover, desc = "查看悬浮文档" },
	{ "<leader>cp", vim.diagnostic.goto_prev, desc = "上一个诊断" },
	{ "<leader>cn", vim.diagnostic.goto_next, desc = "下一个诊断" },
	{ "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "LSP 代码符号列表" },
	{ "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP 定义/引用树" },

	-- 终端管理组 (Snacks.terminal)
	{ "<leader>t", group = "终端管理 (Terminal)" },
	{ "<leader>tn", function() snacks_term_toggle("float", 1) end, desc = "新建浮动终端" },
	{ "<leader>th", function() snacks_term_toggle("bottom", 2) end, desc = "新建底部终端" },
	{ "<leader>tk", "<cmd>close<CR>", desc = "关闭当前终端窗口" },

	-- Git 状态管理组 (所有 Hunk 高级操作已彻底打平整合至此)
	{ "<leader>g", group = "Git 状态管理" },
	{ "<leader>gs", "<cmd>Gitsigns toggle_signs<CR>", desc = "开关左侧状态线" },
	{ "<leader>gg", function() require("snacks.lazygit").open() end, desc = "LazyGit" },
	{ "<leader>gL", function() require("snacks.lazygit").log() end, desc = "LazyGit 提交日志" },
	{ "<leader>gF", function() require("snacks.lazygit").log_file() end, desc = "LazyGit 当前文件日志" },
	{ "<leader>gl", "<cmd>Gitsigns preview_hunk_inline<CR>", desc = "预览当前行改动 (Inline)" },
	{ "<leader>gk", "<cmd>Gitsigns prev_hunk<CR>", desc = "上一个改动块" },
	{ "<leader>gj", "<cmd>Gitsigns next_hunk<CR>", desc = "下一个改动块" },
	-- 以下为原高级 hunk 操作，现在通过单键直达
	{
		"<leader>gP",
		function()
			require("gitsigns").preview_hunk()
		end,
		desc = "弹窗预览当前修改块",
	},
	{
		"<leader>gr",
		function()
			require("gitsigns").reset_hunk()
		end,
		desc = "撤销当前修改块 (Reset)",
	},
	{
		"<leader>ga",
		function()
			require("gitsigns").stage_hunk()
		end,
		desc = "暂存当前修改块 (Stage)",
	},
	{
		"<leader>gb",
		function()
			require("gitsigns").blame_line({ full = true })
		end,
		desc = "查看当前行完整 Blame",
	},
	{
		"<leader>gd",
		function()
			require("gitsigns").diffthis()
		end,
		desc = "对比当前文件与 Git 差异",
	},

	-- 代码诊断看板组 (Trouble / Loclist)
	{ "<leader>a", group = "代码诊断看板 (Debug)" },
	{ "<leader>as", vim.diagnostic.setloclist, desc = "打开错误位置列表" },
	{ "<leader>ad", vim.diagnostic.open_float, desc = "浮窗查看错误" },
	{ "<leader>ap", vim.diagnostic.goto_prev, desc = "上一个错误" },
	{ "<leader>an", vim.diagnostic.goto_next, desc = "下一个错误" },
	{ "<leader>ax", "<cmd>Trouble diagnostics toggle<cr>", desc = "项目全局错误看板" },
	{ "<leader>aX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "当前文件错误看板" },
	{ "<leader>aq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix 增强列表" },
	{ "<leader>al", "<cmd>Trouble loclist toggle<cr>", desc = "Loclist 位置列表" },

	-- 代码调试组 (DAP)
	{ "<leader>d", group = "代码调试 (Debug)" },
	{ "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "断点开关" },
	{
		"<leader>dB",
		function()
			require("dap").set_breakpoint(vim.fn.input("断点条件: "))
		end,
		desc = "条件断点",
	},
	{ "<leader>dc", "<cmd>DapStart<CR>", desc = "启动/继续调试" },
	{
		"<leader>ds",
		function()
			local dap = require("dap")
			local configs = dap.configurations[vim.bo.filetype] or {}
			if #configs == 0 then
				vim.notify("当前文件类型没有调试配置: " .. vim.bo.filetype, vim.log.levels.WARN)
				return
			end
			vim.ui.select(configs, {
				prompt = "选择调试配置:",
				format_item = function(c)
					return c.name
				end,
			}, function(conf)
				if conf then
					dap.run(conf)
				end
			end)
		end,
		desc = "选择调试配置（含 attach）",
	},
	{ "<leader>di", function() require("dap").step_into() end, desc = "步入 (Into)" },
	{ "<leader>do", function() require("dap").step_over() end, desc = "步过 (Over)" },
	{ "<leader>du", function() require("dap").step_out() end, desc = "步出 (Out)" },
	{
		"<leader>da",
		function()
			local dap = require("dap")
			local args = vim.split(vim.fn.input("运行参数: ") or "", "%s+", { trimempty = true })
			for _, conf in ipairs(dap.configurations.python) do
				if conf.name == "▶ 调试当前文件" then
					conf.args = args
				end
			end
			dap.continue()
		end,
		desc = "调试当前文件（带参数）",
	},
	{ "<leader>dr", function() require("dap").repl.toggle() end, desc = "REPL 控制台开关" },
	{ "<leader>dt", function() require("dapui").toggle() end, desc = "调试 UI 开关" },
	{
		"<leader>dl",
		function()
			for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
				if vim.b[bufnr]["dap-type"] and vim.bo[bufnr].buftype == "terminal" then
					vim.cmd("bel sb " .. bufnr)
					return
				end
			end
			vim.notify("没有调试终端，先按 F5 启动调试", vim.log.levels.WARN)
		end,
		desc = "查看调试终端输出",
	},
	{ "<leader>de", function() require("dapui").eval() end, desc = "评估变量/表达式" },
	{ "<leader>dR", function() require("dap").restart() end, desc = "重启调试会话" },
	{ "<leader>dQ", function() require("dap").terminate() end, desc = "终止调试会话" },

	-- 标签页缓冲区管理 (Buffer)
	{ "<leader>b", group = "标签页管理 (Buffer)" },
	{ "<leader>bd", "<cmd>bdelete!<CR>", desc = "强行关闭当前标签页" },
	{ "<leader>bn", "<cmd>BufferLineCycleNext<CR>", desc = "切换到下一个标签" },
	{ "<leader>bp", "<cmd>BufferLineCyclePrev<CR>", desc = "切换到上一个标签" },

	-- 窗口分屏管理 (Window)
	{ "<leader>w", group = "窗口布局(Window)" },
	{ "<leader>wv", "<C-w>v", desc = "垂直分屏" },
	{ "<leader>wh", "<cmd>split<CR>", desc = "水平分屏" },
	{ "<leader>wc", "<C-w>c", desc = "关闭当前窗口" },
	{ "<leader>wo", "<C-w>o", desc = "最大化当前窗口" },

	-- 界面交互与 UI 开关
	{ "<leader>u", group = "界面 (UI)" },
	{ "<leader>u1", "<cmd>set nu! rnu!<CR>", desc = "切换行号显示" },
	{ "<leader>e", snacks_explorer_toggle, desc = "侧边文件树开关" },
	{ "<leader>un", snacks_explorer_toggle, desc = "侧边文件树开关" },
	{ "<leader>uf12", "<cmd>AerialToggle! right<CR>", desc = "代码结构树开关" },
	{
		"<leader>us",
		function()
			require("flash").jump()
		end,
		desc = "Flash 局部闪现跳转",
	},

	-- 系统核心配置 (Config)
	{ "<leader>o", group = "系统配置(Config file)" },
	{ "<leader>oc", "<cmd>edit ~/.config/nvim/init.lua<CR>", desc = "编辑 Neovim 主配置" },
	{ "<leader>ou", "<cmd>Lazy update<CR>", desc = "一键更新所有插件" },
	{ "<leader>oq", "<cmd>qa<CR>", desc = "安全退出 Neovim" },

	-- 文件存取
	{ "<leader>s", group = "文件存取(Save file)" },
	{ "<leader>ss", "<cmd>w<CR>", desc = "保存当前文件" },
	{ "<leader>sc", function() Snacks.scratch() end, desc = "临时草稿缓冲" },
	{ "<leader>sS", "<cmd>w!<CR>", desc = "强制保存当前文件" },
	{ "<leader>sw", ":w ", desc = "文件另存为..." },
	{ "<leader>sa", "<cmd>wa<CR>", desc = "保存所有打开文件" },
	{ "<leader>sq", "<cmd>q<CR>", desc = "退出当前窗口" },
})

-- 终端模式 (Terminal Mode) 菜单
wk.add({
	mode = "t",
	{ "<leader>", group = "终端快捷菜单" },
	{ "<leader>tn", snacks_term_hide, desc = "收起终端回到代码" },
})
