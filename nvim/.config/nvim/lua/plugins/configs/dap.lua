-- =========================================================================
-- nvim-dap 核心调试配置（适配器 + 高频快捷键 + 断点图标）
-- 说明：<leader>d* 调试菜单统一在 lua/configs/keymaps.lua 的 which-key 中管理
-- =========================================================================
return function()
	local ok, dap = pcall(require, "dap")
	if not ok then
		return
	end

	-- ---------------------------------------------------------------------
	-- 1. 高频全局快捷键（无需 Leader）
	-- ---------------------------------------------------------------------
	-- 🌟 智能启动：已有会话则继续，否则自动跑当前文件类型的 launch 配置（不再弹选择框）
	-- 优先选 program=${file} 的配置（如 Python），否则取第一个 launch 配置（如 codelldb 的 LLDB: Launch）
	local function start_debug()
		if dap.session() then
			dap.continue()
			return
		end
		local configs = dap.configurations[vim.bo.filetype] or {}
		local preferred
		for _, conf in ipairs(configs) do
			if conf.request == "launch" and conf.program == "${file}" then
				preferred = conf
				break
			end
		end
		if not preferred then
			for _, conf in ipairs(configs) do
				if conf.request == "launch" then
					preferred = conf
					break
				end
			end
		end
		if preferred then
			dap.run(preferred)
		else
			dap.continue()
		end
	end

	vim.api.nvim_create_user_command("DapStart", start_debug, { desc = "启动/继续调试当前文件" })

	vim.keymap.set("n", "<F5>", start_debug, { desc = "启动/继续调试" })
	vim.keymap.set("n", "<F3>", function()
		dap.toggle_breakpoint()
	end, { desc = "切换断点" })

	-- ---------------------------------------------------------------------
	-- 2. Python 调试适配器（基于 debugpy）
	--    python 解析链（逐个验证 debugpy 可导入，避免选到没装 debugpy 的 venv）：
	--    当前虚拟环境 -> Mason 安装的 debugpy -> 系统 python3
	-- ---------------------------------------------------------------------
	local function has_debugpy(python)
		if not python or vim.fn.filereadable(python) ~= 1 then
			return false
		end
		vim.fn.system({ python, "-c", "import debugpy" })
		return vim.v.shell_error == 0
	end

	local function get_debugpy_python()
		local candidates = {}
		local venv = os.getenv("VIRTUAL_ENV")
		if venv then
			candidates[#candidates + 1] = venv .. "/bin/python"
		end
		candidates[#candidates + 1] = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
		candidates[#candidates + 1] = vim.fn.exepath("python3")
		for _, python in ipairs(candidates) do
			if has_debugpy(python) then
				return python
			end
		end
		-- 全部失败时兜底返回第一个候选（会报错，但日志可定位）
		return candidates[1]
	end

	dap.adapters.python = function(cb)
		cb({
			type = "executable",
			command = get_debugpy_python(),
			args = { "-m", "debugpy.adapter" },
		})
	end

	dap.configurations.python = {
		{
			type = "python",
			request = "launch",
			name = "▶ 调试当前文件",
			program = "${file}",
			args = {},
			console = "integratedTerminal",
			justMyCode = false,
		},
		{
			type = "python",
			request = "attach",
			name = "🔗 附加到远程进程 (5678)",
			connect = { host = "127.0.0.1", port = 5678 },
		},
	}

	-- ---------------------------------------------------------------------
	-- 3. 断点/停止位图标美化（替换默认 >> 标记）
	-- ---------------------------------------------------------------------
	local function setup_dap_signs()
		local c = require("configs.themes").get()
		vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = c.red })
		vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = c.yellow })
		vim.api.nvim_set_hl(0, "DapLogPoint", { fg = c.green })
		vim.api.nvim_set_hl(0, "DapStopped", { fg = c.blue })
	end
	vim.api.nvim_create_autocmd("ColorScheme", {
		pattern = "*",
		callback = setup_dap_signs,
	})
	setup_dap_signs()

	vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
	vim.fn.sign_define("DapBreakpointCondition", { text = "◉", texthl = "DapBreakpointCondition" })
	vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint" })
	vim.fn.sign_define("DapStopped", { text = "→", texthl = "DapStopped" })

	-- ---------------------------------------------------------------------
	-- 4. mason-nvim-dap：自动安装/管理调试器（需在 python 适配器配置之后调用）
	-- ---------------------------------------------------------------------
	local ok_mnd, mnd = pcall(require, "mason-nvim-dap")
	if ok_mnd then
		mnd.setup({
			automatic_installation = true, -- 检测到 adapter 即自动从 Mason 安装对应调试器
			ensure_installed = { "debugpy" },
			handlers = {
				-- Python 适配器/配置由本文件自持，禁用自动生成以免覆盖
				python = function() end,
			},
		})
	end
end
