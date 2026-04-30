-- Lazy.nvim 安装
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 插件列表
require("lazy").setup({
  -- 3.1 配色主题
  { "morhetz/gruvbox" },
  { "loctvl842/monokai-pro.nvim" },
  { "UtkarshVerma/molokai.nvim" },
  { "folke/tokyonight.nvim" },
  { "catppuccin/nvim", name = "catppuccin" },
  { "rebelot/kanagawa.nvim" },
  { "EdenEast/nightfox.nvim" },

  -- 3.2 LSP 与补全
  { "neovim/nvim-lspconfig" },                -- LSP 核心
  { "hrsh7th/nvim-cmp" },                     -- 补全核心
  { "hrsh7th/cmp-nvim-lsp" },                 -- LSP 补全源
  { "L3MON4D3/LuaSnip" },                     -- 代码片段引擎
  { "saadparwaiz1/cmp_luasnip" },             -- 代码片段补全源
  { "rafamadriz/friendly-snippets" },         -- 代码片段库
  { "hrsh7th/cmp-path" },                     -- 路径补全
  { "hrsh7th/cmp-buffer" },                   -- 缓冲区补全
  { "windwp/nvim-autopairs" },                -- 括号自动补全

  -- 3.3 颜色高亮
  { "norcalli/nvim-colorizer.lua" },

  -- 3.4 导航与搜索
  { "preservim/nerdtree" },                   -- 文件浏览器
  { "jistr/vim-nerdtree-tabs" },              -- NERDTree 标签支持
  { "ryanoasis/vim-devicons" },               -- 图标支持
  { "easymotion/vim-easymotion" },            -- 快速跳转
  { "junegunn/fzf" },                         -- 模糊搜索
  { "junegunn/fzf.vim" },                     -- FZF Vim 集成
  { "tpope/vim-fugitive" },                   -- Git 集成
  { "preservim/tagbar" },                     -- 代码标签导航

  -- 3.5 编辑增强
  { "tmhedberg/SimpylFold" },                 -- Python 折叠
  { "Yggdroot/indentLine" },                  -- 缩进线
  { "preservim/nerdcommenter" },              -- 代码注释
  { "luochen1990/rainbow" },                  -- 彩虹括号
  { "voldikss/vim-floaterm" },                -- 浮动终端
  { "linux-cultist/venv-selector.nvim" },     -- python 虚拟环境
  { "nvim-telescope/telescope.nvim" },

  -- 3.6 代码检查与格式化
  { "w0rp/ale" },                             -- 代码检查
  { "nvie/vim-flake8" },                      -- Python 代码检查

  -- 3.7 UI 增强
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' }
  },                                           -- 状态栏
  { "glepnir/dashboard-nvim" },               -- 启动页
  { "yuttie/comfortable-motion.vim" },        -- 平滑滚动
  { "akinsho/bufferline.nvim" },              -- 缓冲区多标签页
  { "folke/which-key.nvim" },
}, {
  ui = {
    border = "rounded",                       -- 圆角 UI
  },
  performance = {
    rtp = {
      disabled_plugins = {                    -- 禁用冗余插件
        "netrw", "netrwPlugin", "netrwSettings", "netrwFileHandlers",
        "gzip", "zip", "zipPlugin", "tar", "tarPlugin",
        "getscript", "getscriptPlugin", "vimball", "vimballPlugin",
        "2html_plugin", "logiPat", "rrhelper", "spellfile_plugin", "matchit",
      },
    },
  },
})


-- 加载各插件的具体配置
require("plugins.configs.cmp")
require("plugins.configs.lsp")
require("plugins.configs.ui")
require("plugins.configs.editor")
require("plugins.configs.tools")
