-- 确保 UTF-8 编码
vim.scriptencoding = "utf-8"
vim.opt.encoding = "utf-8"

-- 1. 加载基础环境配置
require("configs.base")

-- 2. 加载插件管理器 + 插件列表
require("plugins")

-- 3. 加载 主题 美化（主题/透明/高亮）
require("configs.theme")

-- 4. 加载自动命令
require("configs.filetype")

-- 5. 加载快捷键配置
require("configs.keymaps")

-- 自定义命令：导出 messages 到日志文件
vim.api.nvim_create_user_command("SaveMsg", "redir! > ~/nvim_messages.log | messages | redir END", {})
-- vim.api.nvim_create_user_command("SaveMsg", "redir! > ~/nvim_messages.log | silent NoiceDispatch history | redir END", {})
-- Lua语法设置 conceallevel=0，关闭字符隐藏
vim.opt.conceallevel = 0
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	pattern = { "*" },
	callback = function()
		vim.opt.conceallevel = 0
	end,
})

-- 用最干净的方式关闭默认虚拟文本，不要重复定义同一个 key
vim.diagnostic.config({
	virtual_text = false, -- 严格关闭默认的行尾提示
	underline = true, -- 保留代码下方波浪线
	update_in_insert = false, -- 插入模式下不触发报错
})

-- 【关键防护】防止子模块（如 plugins 或 theme）异步加载时重新覆盖该配置
vim.api.nvim_create_autocmd("User", {
	pattern = "LspAttach", -- 当 LSP 启动时，再次强制确保 virtual_text 关闭
	callback = function()
		vim.diagnostic.config({ virtual_text = false })
	end,
})
