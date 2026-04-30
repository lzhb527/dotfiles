-- 确保 UTF-8 编码
vim.scriptencoding = "utf-8"
vim.opt.encoding = "utf-8"

-- 1. 加载基础环境配置
require("base")

-- 2. 加载插件管理器 + 插件列表
require("plugins")

-- 3. 加载 UI 美化（主题/透明/高亮）
require("ui")

-- 4. 加载自动命令
require("autocmds")

-- 5. 加载快捷键配置
require("keymaps")

-- 自定义命令：导出 messages 到日志文件
vim.api.nvim_create_user_command("SaveMsg", "redir! > ~/nvim_messages.log | messages | redir END", {})
-- Lua语法设置 conceallevel=0，关闭字符隐藏
vim.opt.conceallevel = 0
