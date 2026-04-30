local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- FZF 快捷键（which-key 中会覆盖为二级菜单）
map('n', '<leader>f', ":Files<CR>", { noremap = true, silent = true, desc = "查找文件" })
map('n', '<leader>fg', ":Rg<CR>", { noremap = true, silent = true, desc = "全局搜索" })
map('n', '<leader>fb', ":Buffers<CR>", { noremap = true, silent = true, desc = "查找缓冲区" })
map('n', '<leader>fh', ":History<CR>", { noremap = true, silent = true, desc = "查看历史" })
map('n', '<leader>fc', ":Commits<CR>", { noremap = true, silent = true, desc = "查看提交记录" })
map('n', '<leader>fr', ":Rg <C-R><C-W><CR>", { noremap = true, silent = true, desc = "搜索当前单词" })

-- 注释快捷键（which-key 中会覆盖为二级菜单）
vim.api.nvim_set_keymap("n", "<leader>cc", "<Plug>NERDCommenterComment", {noremap=false, silent=true, desc="注释代码"})
vim.api.nvim_set_keymap("v", "<leader>cc", "<Plug>NERDCommenterComment", {noremap=false, silent=true, desc="注释代码"})
vim.api.nvim_set_keymap("n", "<leader>cv", "<Plug>NERDCommenterUncomment", {noremap=false, silent=true, desc="取消注释"})
vim.api.nvim_set_keymap("v", "<leader>cv", "<Plug>NERDCommenterUncomment", {noremap=false, silent=true, desc="取消注释"})

-- 终端快捷键
-- 普通模式
map("n", "<F8>", "<cmd>FloatermNew<CR>", { silent = true, desc = "新建浮动终端" })
map("n", "<F9>", "<cmd>FloatermToggle<CR>", { silent = true, desc = "切换终端显示" })
map("n", "<F10>", "<cmd>FloatermNext<CR>", { silent = true, desc = "下一个终端" })
map("n", "<F11>", "<cmd>FloatermKill<CR>", { silent = true, desc = "关闭当前终端" })

-- 终端模式
map("t", "<F8>", "<C-\\><C-n><cmd>FloatermNew<CR>", { silent = true, desc = "新建浮动终端" })
map("t", "<F9>", "<C-\\><C-n><cmd>FloatermToggle<CR>", { silent = true, desc = "切换终端显示" })
map("t", "<F10>", "<C-\\><C-n><cmd>FloatermNext<CR>", { silent = true, desc = "下一个终端" })
map("t", "<F11>", "<C-\\><C-n><cmd>FloatermKill<CR>", { silent = true, desc = "关闭当前终端" })

-- Easymotion 快捷键
vim.api.nvim_set_keymap("n", "/", "<Plug>(easymotion-sn)", {noremap=false, silent=true, desc="Easymotion搜索"})
vim.api.nvim_set_keymap("v", "/", "<Plug>(easymotion-sn)", {noremap=false, silent=true, desc="Easymotion搜索"})

-- ALE 快捷键
map('n', 'sp', '<Plug>(ale_previous_wrap)', { noremap = true, desc = "上一个错误" })
map('n', 'sn', '<Plug>(ale_next_wrap)', { noremap = true, desc = "下一个错误" })
map('n', '<leader>a', ":ALEToggle<CR>", { noremap = true, silent = true, desc = "切换ALE" })
map('n', '<leader>d', ":ALEDetail<CR>", { noremap = true, silent = true, desc = "错误详情" })

-- Tagbar 快捷键
map('n', '<F12>', ':TagbarToggle<CR>', {
  noremap = true,
  silent = true,
  desc = '切换Tagbar窗口'
})

-- Bufferline 缓冲区切换
map("n", "<C-Tab>", "<Cmd>BufferLineCycleNext<CR>", opts)
map("n", "<C-S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", opts)
map("n", "<leader>bd", "<Cmd>bdelete!<CR>", opts)
