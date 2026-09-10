-- =========================================================================
-- conform.nvim 配置 (🌟 Ruff 超级一体化流水线托管版)
-- =========================================================================
return function()
	local conform_status, conform = pcall(require, "conform")
	if not conform_status then
		return
	end

	-- ---------------------------------------------------------------------
	-- 🌟 【核心大招】自定义超级一体化 Ruff 格式化器
	-- ---------------------------------------------------------------------
	-- 默认的 ruff_organize_imports 有时会因为 Neovim 根目录判定或 Ruff 版本升级而静默失效。
	-- 这里我们直接写死最底层的命令行参数，强行让 Ruff 在一次调用中同时干完“删导包”和“刷空格”。
	conform.formatters.ruff_all_in_one = {
		command = "ruff",
		-- format: 负责格式化空格和缩进
		-- --line-ending native: 保持换行符正常
		-- --stdin-filename: 让 Ruff 知道当前在处理什么文件以触发相应规则
		args = { "format", "--force-exclude", "--stdin-filename", "$FILENAME", "-" },
	}

	-- 自定义一个专门用来删除未使用导包的底层修复器作为前置流水线
	conform.formatters.ruff_fix_unused = {
		command = "ruff",
		-- check: 运行静态检查
		-- --select F401,I: 精准锁定 F401(未使用导入) 和 I(导入排序)
		-- --fix: 强行自动修复（删除）它们
		args = { "check", "--select", "F401,I", "--fix", "--force-exclude", "--stdin-filename", "$FILENAME", "-" },
	}

	-- ---------------------------------------------------------------------
	-- 核心 Setup 配置
	-- ---------------------------------------------------------------------
	conform.setup({
		-- 🌟 文件类型与格式化器的一对一/多对多映射字典
		formatters_by_ft = {
			lua = { "stylua" },

			-- 🌟 终极必杀连招：保存或手动调用时，先执行强行删导包，再执行强行刷空格！
			python = { "ruff_fix_unused", "ruff_all_in_one" },

			sh = { "shfmt" }, -- 顺便帮您的 Bash 脚本也加上现代格式化
			yaml = { "prettier" },
		},

		-- 🌟 开启自动保存格式化（阻塞同步落盘）
		format_on_save = {
			timeout_ms = 800, -- 适当将超时放大到 800ms，给删导包留出充裕的命令行执行时间
			lsp_fallback = true, -- 如果工具链挂了，尝试降级使用 LSP 原生格式化
		},
	})

	-- 🌟 格式化快捷键 <leader>fm 已由 lua/configs/keymaps.lua 的 smart_format 统一管理，这里不重复绑定
end
