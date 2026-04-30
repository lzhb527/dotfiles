-- 主题配置
vim.o.background = "dark"
vim.g.gruvbox_contrast_dark = "hard"
vim.cmd.colorscheme("molokai")  -- 可替换为其他主题

-- 高亮配置
vim.g.gruvbox_invert_selection = '0'
vim.g.gruvbox_italic = 0
vim.api.nvim_set_hl(0, "@punctuation.bracket", { italic = false })

-- CursorLine 高亮
vim.api.nvim_set_hl(0, "CursorLine", {
  bg = "NONE",
  underline = true,
  sp = "#8ec07c",
  cterm = { underline = true },
  ctermbg = "NONE",
  ctermfg = "NONE"
})

-- 透明背景增强
-- vim.api.nvim_set_hl(0, "Normal", { bg = "none", fg = "none" }) --普通文本背景透明
-- vim.api.nvim_set_hl(0, "NormalNC", { bg = "none", fg = "none" }) -- 非活动窗口透明
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none", fg = "#89b4fa" })
