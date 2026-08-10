-- =========================================================================
-- nvim-dap-ui 调试界面配置
-- =========================================================================
return function()
	local ok, dapui = pcall(require, "dapui")
	if not ok then
		return
	end

	dapui.setup({
		icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
		controls = {
			element = "repl",
			icons = {
				pause = "⏸",
				play = "▶",
				step_into = "⏎",
				step_over = "⏭",
				step_out = "⏮",
				step_back = "◀",
				run_last = "⏽",
				terminate = "⏹",
			},
		},
		layouts = {
			{
				-- 左侧：变量/断点/调用栈/监视
				elements = {
					{ id = "scopes", size = 0.25 },
					{ id = "breakpoints", size = 0.25 },
					{ id = "stacks", size = 0.25 },
					{ id = "watches", size = 0.25 },
				},
				size = 40, -- 宽度
				position = "left",
			},
			{
				-- 底部：REPL 控制台 + 输出
				elements = {
					{ id = "repl", size = 0.5 },
					{ id = "console", size = 0.5 },
				},
				size = 10, -- 高度
				position = "bottom",
			},
		},
		floating = {
			border = "rounded",
		},
	})

	-- ---------------------------------------------------------------------
	-- 会话开启自动打开 UI，结束自动收起（标准行为）
	-- 调试中停在断点时 UI 保持打开；程序跑完/会话结束才收起
	-- ---------------------------------------------------------------------
	local dap = require("dap")
	dap.listeners.after.event_initialized["dapui_config"] = function()
		dapui.open()
	end
	dap.listeners.before.event_terminated["dapui_config"] = function()
		dapui.close()
	end
	dap.listeners.before.event_exited["dapui_config"] = function()
		dapui.close()
	end
end
