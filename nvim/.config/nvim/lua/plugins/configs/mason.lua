-- =========================================================================
-- mason.nvim + mason-lspconfig + mason-tool-installer 联动配置
-- =========================================================================
return function()
	local mason_status, mason = pcall(require, "mason")
	if not mason_status then
		return
	end

	mason.setup()

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
			-- 🌟 关闭内置的自动安装检查，改用手动触发，避免与下方自定义 defer 重复
			run_on_start = false,
		})

		-- 🌟 主动触发一次安装检查
		-- 说明：mason-tool-installer 的 run_on_start 依赖 VimEnter 事件触发，
		-- 但 mason 是懒加载的（作为 nvim-lspconfig 的依赖，往往在 VimEnter 之后才加载），
		-- 导致 VimEnter 事件早已错过，工具永远不会自动安装。
		-- 因此这里手动 defer 一次 check_install，确保 tree-sitter-cli 等工具真正装好。
		vim.defer_fn(function()
			pcall(mason_tool.check_install)
		end, 300)
	end

	-- 将 Mason 的二进制下载目录追加到 Neovim 内部的 PATH 中，防止找不到工具崩溃
	local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
	if not string.find(vim.env.PATH, mason_bin, 1, true) then
		vim.env.PATH = mason_bin .. vim.path_sep .. vim.env.PATH
	end
end
