local map = vim.keymap.set

-- 通用基础快捷键
map('n', '<F1>', ":set nu! rnu!<CR>", { noremap = true, silent = true, desc = "切换行号显示" })
map('n', '<C-n>', ":NERDTreeToggle<CR>", { noremap = true, silent = true, desc = "切换NERDTree" })

-- Python F6 格式化
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    map("n", "<F6>", ":!yapf -i %<CR>:edit<CR>", { buffer = true })
  end
})

-- 保存相关
map('n', '<leader>s', ':w<CR>', { desc = '快速保存文件' })
map('i', '<C-s>', '<Esc>:w<CR>a', { desc = '插入模式快速保存' })
map('v', '<C-s>', '<Esc>:w<CR>gv', { desc = '可视模式快速保存' })
map('n', '<leader>S', ':w!<CR>', { desc = '强制保存文件' })

-- 窗口管理基础快捷键（which-key 中会覆盖为二级菜单）
map('n', '<C-w>v', '<C-w>v', { desc = '垂直分屏' })
map('n', '<C-w>h', '<C-w>h', { desc = '水平分屏' })
map('n', '<C-w>c', '<C-w>c', { desc = '关闭窗口' })
map('n', '<C-w>o', '<C-w>o', { desc = '只保留当前窗口' })
