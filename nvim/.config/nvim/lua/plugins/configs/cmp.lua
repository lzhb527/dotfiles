-- =========================================================================
-- nvim-cmp 补全核心配置（含 LuaSnip 代码片段引擎）
-- =========================================================================
return function()
	-- 安全加载：防止首次启动、插件未下载完时卡死报错
	local cmp_status, cmp = pcall(require, "cmp")
	local luasnip_status, luasnip = pcall(require, "luasnip")

	if not (cmp_status and luasnip_status) then
		return
	end

	-- =========================================================================
	-- 1. Luasnip 代码片段配置
	-- =========================================================================
	require("luasnip.loaders.from_vscode").lazy_load()
	luasnip.config.setup({ history = true, updateevents = "TextChanged,TextChangedI" })

	-- 解决 Ansible 复合文件类型不弹 Snippet 的问题
	luasnip.filetype_extend("yaml.ansible", { "yaml", "ansible" })

	-- =========================================================================
	-- 2. nvim-cmp 核心配置
	-- =========================================================================
	cmp.setup({
		snippet = {
			expand = function(args)
				luasnip.lsp_expand(args.body)
			end,
		},
		mapping = cmp.mapping.preset.insert({
			["<TAB>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_next_item()
				elseif luasnip.expand_or_jumpable() then
					luasnip.expand_or_jump()
				else
					fallback()
				end
			end, { "i", "s" }),
			["<S-TAB>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_prev_item()
				elseif luasnip.jumpable(-1) then
					luasnip.jump(-1)
				else
					fallback()
				end
			end, { "i", "s" }),
			["<CR>"] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Replace }),
			["<ESC>"] = cmp.mapping.abort(),
			["<C-Space>"] = cmp.mapping.complete(),
		}),
		sources = cmp.config.sources({
			{ name = "nvim_lsp", priority = 1000 },
			{ name = "luasnip", priority = 750 },
			{ name = "path", priority = 500 },
			{ name = "buffer", priority = 250 },
		}),
		window = {
			completion = cmp.config.window.bordered({ border = "rounded" }),
			documentation = cmp.config.window.bordered({ border = "rounded" }),
		},
		formatting = {
			fields = { "abbr", "kind", "menu" },
			format = function(entry, vim_item)
				vim_item.menu = ({
					nvim_lsp = "[LSP]",
					luasnip = "[Snippet]",
					path = "[Path]",
					buffer = "[Buffer]",
				})[entry.source.name]
				return vim_item
			end,
		},
	})
end
