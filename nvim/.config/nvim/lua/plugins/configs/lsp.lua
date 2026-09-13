-- =========================================================================
-- nvim-lspconfig: Python (Pyright + Ruff) & Ansible 完美联动核心配置
-- =========================================================================
return function()
	-- ---------------------------------------------------------------------
	-- [1] 核心补全能力与快捷键分发器 (on_attach)
	-- ---------------------------------------------------------------------
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	-- 🌟 补全能力交给 blink.cmp 提供（含 LSP 补全增强字段）
	local has_blink, blink = pcall(require, "blink.cmp")
	if has_blink then
		capabilities = blink.get_lsp_capabilities()
	end

	local on_attach = function(client, bufnr)
		-- 颜色高亮已交给 nvim-colorizer.lua 统一处理（含 LSP 颜色），
		-- 它会自动禁用内置 vim.lsp.document_color 避免重复高亮

		-- 🌟 彻底屏蔽 Pyright 原生的格式化能力，全面交给 Conform 后端的 Ruff
		if client.name == "pyright" then
			client.server_capabilities.documentFormattingProvider = false
		end

		-- 全局通用 LSP 快捷键映射
		local opts = { buffer = bufnr, silent = true, noremap = true }
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
		-- 🌟 诊断弹窗用 which-key 里的 <leader>ce，不再占用 <leader>e（那是 Neotree 的键）
	end

	-- ---------------------------------------------------------------------
	-- [2] Python 服务 ①：Pyright (专职负责类型推导与卓越的代码补全)
	-- ---------------------------------------------------------------------
	vim.lsp.config("pyright", {
		cmd = { "pyright-langserver", "--stdio" },
		root_markers = { "pyproject.toml", "setup.py", "requirements.txt", ".git" },
		capabilities = capabilities,
		on_attach = on_attach,
		settings = {
			python = {
				analysis = {
					autoSearchPaths = true,
					useLibraryCodeForTypes = true,
					-- 🌟【硬核闭嘴指令】彻底封死 Pyright 的代码诊断，避免产生绿色重叠报错提示！
					diagnosticMode = "openFilesOnly",
					typeCheckingMode = "off",
					reportUnusedImport = "none", -- 强行禁止 Pyright 对未消费导包的碎碎念
				},
			},
		},
	})
	vim.lsp.enable("pyright")

	-- ---------------------------------------------------------------------
	-- [3] Python 服务 ②：Ruff LSP (专职负责极致速度的代码语法红线提示)
	-- ---------------------------------------------------------------------
	vim.lsp.config("ruff", {
		cmd = { "ruff", "server" }, -- Neovim 0.10+ 原生支持拉起 ruff 官方内置的 LSP 服务器
		root_markers = { "pyproject.toml", "setup.py", "ruff.toml", ".git" },
		capabilities = capabilities,
		on_attach = function(client, bufnr)
			-- 激活通用快捷键 (gd, K 等)
			on_attach(client, bufnr)

			-- 屏蔽 Ruff 的 hover 提示，防止和 Pyright 的 Hover (K键) 发生弹窗冲突
			client.server_capabilities.hoverProvider = false

			-- 🚨【完美分流】这里面完全清空了原本的 BufWritePre 自动命令！
			-- 因为“保存时删除导包”与“保存时对齐空格”已经通过流水线全权交给了你的 conform.nvim 托管
		end,
	})
	vim.lsp.enable("ruff")

	-- ---------------------------------------------------------------------
	-- [4] Ansible：统一注册，按根目录自动匹配（不再每文件起一个客户端）
	-- ---------------------------------------------------------------------
	local data_path = vim.fn.stdpath("data")
	vim.lsp.config("ansiblels", {
		cmd = { data_path .. "/mason/bin/ansible-language-server", "--stdio" },
		capabilities = capabilities,
		on_attach = on_attach,
		root_markers = { ".git", "ansible.cfg", "requirements.yml", "ansible-navigator.yml" },
		filetypes = { "yaml.ansible" },
		settings = {
			ansible = {
				python = { interpreterPath = vim.fn.exepath("python3") },
				ansible = { path = vim.fn.exepath("ansible") },
				validation = { enabled = true, lint = { enabled = false } },
			},
		},
	})
	vim.lsp.enable("ansiblels")

	-- yaml 文件类型识别
	vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
		pattern = { "*.yml", "*.yaml" },
		callback = function(args)
			vim.bo[args.buf].filetype = "yaml.ansible"
		end,
	})
end
