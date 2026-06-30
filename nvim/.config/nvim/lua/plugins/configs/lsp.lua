-- =====================================================================
-- Neovim 0.10+ Python (Pyright + Ruff) & Ansible 完美联动核心配置
-- =====================================================================

-- ---------------------------------------------------------------------
-- [0] 联动 Mason-Tool-Installer：确保所需工具一开机就自动下载就位
-- ---------------------------------------------------------------------
local mt_status, mason_tool = pcall(require, "mason-tool-installer")
local ml_status, mason_lsp = pcall(require, "mason-lspconfig")

if ml_status then
	mason_lsp.setup({
		-- 核心三大 LSP 服务 (注意：Ruff 作为 LSP 注册，而格式化交给 Conform)
		ensure_installed = { "pyright", "ansiblels", "ruff" },
	})
end

if mt_status then
	mason_tool.setup({
		-- 让 Mason 自动帮你把底下的静态检查器与格式化命令行工具也一并下载到本地！
		ensure_installed = { "ansible-lint", "stylua", "prettier", "tree-sitter-cli", "shfmt" },
		auto_update = true,
		run_on_start = true,
	})
end

-- 将 Mason 的二进制下载目录追加到 Neovim 内部的 PATH 中，防止找不到工具崩溃
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
if not string.find(vim.env.PATH, mason_bin, 1, true) then
	vim.env.PATH = mason_bin .. vim.path_sep .. vim.env.PATH
end

-- ---------------------------------------------------------------------
-- [1] 核心补全能力与快捷键分发器 (on_attach)
-- ---------------------------------------------------------------------
local capabilities = vim.lsp.protocol.make_client_capabilities()
if vim.lsp.default_capabilities then
	capabilities = vim.lsp.default_capabilities()
end
local has_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if has_cmp then
	capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
end

local on_attach = function(client, bufnr)
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
	vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
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
-- [4] Ansible 服务：ansiblels (文件精准感知与自动匹配)
-- ---------------------------------------------------------------------
local data_path = vim.fn.stdpath("data")
local ansiblels_config = {
	name = "ansiblels",
	cmd = { data_path .. "/mason/bin/ansible-language-server", "--stdio" },
	capabilities = capabilities,
	on_attach = on_attach,
	settings = {
		ansible = {
			python = { interpreterPath = vim.fn.exepath("python3") },
			ansible = { path = vim.fn.exepath("ansible") },
			validation = { enabled = true, lint = { enabled = false } },
		},
	},
}

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = { "*.yml", "*.yaml" },
	callback = function(args)
		vim.bo[args.buf].filetype = "yaml.ansible"
		local current_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(args.buf))
		local final_config = vim.tbl_deep_extend("force", ansiblels_config, {
			root_dir = current_dir,
		})
		vim.lsp.start(final_config, { bufnr = args.buf })
	end,
})

-- ---------------------------------------------------------------------
-- [5] Python 虚拟环境自动加载 (Venv-Selector 联动)
-- ---------------------------------------------------------------------
local venv_status, venv_selector = pcall(require, "venv-selector")
if venv_status then
	venv_selector.setup({
		auto_refresh = true,
		search_workspace = true,
		search_venv_managers = true,
		name = { "venv", ".venv", "env" },
		auto_select = true,
	})

	vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
		pattern = "python",
		callback = function()
			vim.cmd("silent! VenvSelectCached")
		end,
	})
end
