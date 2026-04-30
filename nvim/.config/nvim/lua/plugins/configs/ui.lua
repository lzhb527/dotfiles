-- lualine 状态栏
local function python_venv()
  -- 1. venv / virtualenv / poetry
  local venv = os.getenv("VIRTUAL_ENV")
  if venv and venv ~= "" then
    return "󰌠 " .. vim.fn.fnamemodify(venv, ":t")
  end

  -- 2. conda / mamba
  local conda = os.getenv("CONDA_DEFAULT_ENV")
  if conda and conda ~= "" then
    return "󱔎 " .. conda
  end

  return ""
end


require('lualine').setup({
  options = {
    theme = 'auto',
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
    disabled_filetypes = { 'NvimTree', 'dashboard' },
    globalstatus = true,
    refresh = { statusline = 1000 },
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch', 'diff' },
    lualine_c = { 'filename', python_venv, },
    lualine_x = { 'encoding', 'fileformat', 'filetype' },
    lualine_y = { 'progress' },
    lualine_z = { 'location' }
  },
})

-- bufferline 缓冲区标签
require("bufferline").setup({
  options = {
    mode = "buffers",
    numbers = "ordinal",
    close_command = "bdelete! %d",
    separator_style = "slant",
    always_show_bufferline = true,
    offsets = {
      {
        filetype = "NvimTree",
        text = "文件浏览器",
        separator = true
      }
    }
  },
  highlights = {
    modified = { bg = "none", fg = "#fabd2f" }
  },
})

-- dashboard 启动页
local status_ok, dashboard = pcall(require, "dashboard")
if status_ok then
  dashboard.setup({
    theme = "hyper",
    config = {
      header = {
        "                                                     ",
        "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
        "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
        "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
        "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
        "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
        "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
        "                                                     ",
      },
      center = {
        { icon = "  ", desc = "新建文件", action = "enew", key = "n" },
        { icon = "󰈞  ", desc = "最近文件", action = "oldfiles", key = "r" },
        { icon = "  ", desc = "编辑配置", action = "edit ~/.config/nvim/init.lua", key = "c" },
        { icon = "󰗼  ", desc = "退出", action = "qa", key = "q" },
      },
      footer = { " Neovim " },
      shortcut = {
        { desc = "󰊳 UPDATE", group = "@property", action = "Lazy update", key = "u" },
      },
      project = { enable = false },
    },
    hide = { statusline = true, tabline = true, winbar = true },
  })
end

-- colorizer 颜色高亮
require('colorizer').setup({
  '*',
  css = { rgb_fn = true },
  html = { names = true },
})

-- indentLine 缩进线
vim.g.indentLine_fileTypeExclude = {
  "dashboard", "alpha", "NvimTree", "lazy", "mason", "terminal", "help"
}

-- rainbow 彩虹括号
vim.g.rainbow_active = 1
vim.g.rainbow_conf = {
  guifgs = {'#fb4934','#b8bb26','#83a598','#d3869b','#8ec07c'},
  ctermfgs = {'red','yellow','cyan','magenta','green'},
  separate = 'yes'
}
