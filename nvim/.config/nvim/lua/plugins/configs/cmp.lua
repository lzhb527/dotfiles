-- =========================================================================
-- 安全加载：防止首次启动、插件未下载完时卡死报错
-- =========================================================================
local cmp_status, cmp = pcall(require, "cmp")
local luasnip_status, luasnip = pcall(require, "luasnip")
local autopairs_status, autopairs = pcall(require, "nvim-autopairs")

if not (cmp_status and luasnip_status and autopairs_status) then 
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
    expand = function(args) luasnip.lsp_expand(args.body) end
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

-- =========================================================================
-- 3. nvim-autopairs 括号自动补全与优化
-- =========================================================================
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
    highlight_grey = "Comment"
  }
})

-- 针对 Ansible 变量 {{ }} 的特殊空格联动（已修复 col 报错隐患）
local Rule = require('nvim-autopairs.rule')
local cond = require('nvim-autopairs.conds')

autopairs.add_rules({
  Rule(' ', ' ')
    :with_pair(function(opts)
      local pair = opts.line:sub(opts.col - 1, opts.col)
      return vim.tbl_contains({ '()', '[]', '{}' }, pair)
    end)
    :with_move(cond.none())
    :with_cr(cond.none())
    :with_del(function(opts)
      local col = opts.col
      local context = opts.line:sub(col - 1, col + 2)
      return vim.tbl_contains({ '(  )', '[  ]', '{  }' }, context)
    end),
  Rule('{{', '}}', { "yaml", "yaml.ansible" })
    :with_pair(cond.not_after_regex('%}'))
})

-- 补全与括号联动
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

