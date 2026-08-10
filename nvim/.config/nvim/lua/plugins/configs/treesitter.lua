-- =========================================================================
-- nvim-treesitter + ts-install 配置
-- =========================================================================
return function()
	-- 1. 先初始化 ts-install（自动安装缺失解析器）
	local ok_install, ts_install = pcall(require, "ts-install")
	if ok_install then
		ts_install.setup({
			auto_install = true,
		})
	end

	-- 2. 🚀 新版 nvim-treesitter（2025+ 重构版）初始化姿势
	local status_ok, treesitter = pcall(require, "nvim-treesitter")
	if not status_ok then
		return
	end

	treesitter.setup({})

	-- 基础解析器强制锁死安装（已装过的会跳过）
	local parsers = { "lua", "vim", "vimdoc", "query", "markdown", "python", "javascript" }

	-- 🌟 新版 nvim-treesitter 编译解析器依赖 tree-sitter CLI（由 mason 提供）。
	-- mason 是懒加载的，tree-sitter-cli 下载需要时间，这里等 CLI 就绪后再安装，
	-- 否则会出现 ENOENT: 'tree-sitter' 报错。
	local function ensure_parsers(tries)
		if vim.fn.executable("tree-sitter") == 1 then
			treesitter.install(parsers)
		elseif tries > 0 then
			vim.defer_fn(function()
				ensure_parsers(tries - 1)
			end, 3000)
		else
			vim.notify(
				"tree-sitter CLI 未就绪，解析器安装已跳过。请稍后运行 :MasonToolsInstall 后再 :TSInstallSync all",
				vim.log.levels.WARN
			)
		end
	end

	ensure_parsers(10) -- 最多重试 10 次（约 30 秒），等待 mason 装好 tree-sitter-cli
end
