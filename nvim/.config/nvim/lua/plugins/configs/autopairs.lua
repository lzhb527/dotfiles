-- =========================================================================
-- nvim-autopairs 括号自动补全配置
-- =========================================================================
return function()
	local autopairs_status, autopairs = pcall(require, "nvim-autopairs")
	if not autopairs_status then
		return
	end

	autopairs.setup({
		check_ts = true,
		ts_config = {
			python = { "string", "comment" },
			lua = { "string", "comment" },
			yaml = { "string", "comment" }, -- 增加对 YAML 的 Treesitter 检查
		},
		disable_filetype = { "TelescopePrompt", "vim" },
		fast_wrap = {
			map = "<M-e>",
			chars = { "{", "[", "(", '"', "'", '"""', "'''" },
			pattern = [=[[%'%"%)%>%]%)%}%,]]=],
			end_key = "$",
			keys = "qwertyuiopzxcvbnmasdfghjkl",
			check_comma = true,
			highlight = "Search",
			highlight_grey = "Comment",
		},
	})

	-- 针对 Ansible 变量 {{ }} 的特殊空格联动（已修复 col 报错隐患）
	local Rule = require("nvim-autopairs.rule")
	local cond = require("nvim-autopairs.conds")

	autopairs.add_rules({
		Rule(" ", " ")
			:with_pair(function(opts)
				local pair = opts.line:sub(opts.col - 1, opts.col)
				return vim.tbl_contains({ "()", "[]", "{}" }, pair)
			end)
			:with_move(cond.none())
			:with_cr(cond.none())
			:with_del(function(opts)
				local col = opts.col
				local context = opts.line:sub(col - 1, col + 2)
				return vim.tbl_contains({ "(  )", "[  ]", "{  }" }, context)
			end),
		Rule("{{", "}}", { "yaml", "yaml.ansible" })
			:with_pair(cond.not_after_regex("%}")),
	})

	-- 补全确认后的括号联动由 blink.cmp 的 auto_brackets 负责（见 blink.lua），
	-- 不再依赖 nvim-cmp 的 confirm_done 事件
end
