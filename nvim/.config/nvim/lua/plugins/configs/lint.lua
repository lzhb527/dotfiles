return function()
	local ok, lint = pcall(require, "lint")
	if not ok then
		return
	end

	-- 直接用 nvim-lint 内置的 shellcheck / yamllint 定义（比手写更可靠）
	lint.linters_by_ft = {
		sh = { "shellcheck" },
		bash = { "shellcheck" },
		yaml = { "yamllint" },
		["yaml.ansible"] = { "yamllint" },
	}

	-- 保存时自动跑 linter
	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		callback = function()
			lint.try_lint()
		end,
	})
end
