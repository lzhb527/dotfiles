-- =========================================================================
-- nvim-treesitter 配置（新版：仅负责解析器安装，语法高亮由 Neovim 内置）
-- 说明：新版 nvim-treesitter 的 setup 只接受 install_dir，无 ensure_installed，
--       解析器安装统一走内置的 :TSInstall（依赖 Mason 提供的 tree-sitter CLI）
-- =========================================================================
return function()
	local ok, treesitter = pcall(require, "nvim-treesitter")
	if not ok then
		return
	end

	treesitter.setup({})

	-- 需要的解析器清单
	local parsers = { "lua", "vim", "vimdoc", "query", "markdown", "python", "javascript", "c", "bash", "yaml" }

	-- 🌟 只安装缺失的解析器；已装的不重建，避免每次启动重复编译
	local function ensure_parsers()
		local installed = treesitter.get_installed("parsers")
		local missing = vim.tbl_filter(function(p)
			return not vim.tbl_contains(installed, p)
		end, parsers)

		if #missing == 0 then
			return
		end
		if vim.fn.executable("tree-sitter") ~= 1 then
			vim.notify(
				"tree-sitter CLI 未就绪，缺失解析器跳过。可稍后运行 :TSInstallSync "
					.. table.concat(missing, " "),
				vim.log.levels.WARN
			)
			return
		end
		vim.cmd("TSInstall " .. table.concat(missing, " "))
	end

	-- 延迟到 Mason 就绪后再装，避免加载期阻塞
	vim.defer_fn(ensure_parsers, 800)
end
