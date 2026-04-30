local api = vim.api

-- Dashboard 禁用缩进线
api.nvim_create_autocmd("FileType", {
  pattern = "dashboard",
  callback = function()
    vim.b.indentLine_enabled = 0
    vim.opt_local.list = false
    vim.opt_local.listchars = ""
    pcall(vim.cmd, "IndentLinesDisable")
  end,
})

-- 光标线设置
api.nvim_create_autocmd('InsertEnter', {command='set nocursorline'})
api.nvim_create_autocmd('InsertLeave', {command='set cursorline'})

-- 配色方案加载后重新应用 CursorLine 高亮
api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    api.nvim_set_hl(0, "CursorLine", {
      fg = "NONE",
      bg = "NONE",
      underline = true,
      sp = "#8ec07c",
      ctermfg = "NONE",
      ctermbg = "NONE",
      cterm = "underline"
    })
  end
})
