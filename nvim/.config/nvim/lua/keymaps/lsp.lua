local map = vim.keymap.set

-- LSP 诊断跳转
map("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", { noremap = true, silent = true, desc = "上一个诊断" })
map("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", { noremap = true, silent = true, desc = "下一个诊断" })

-- LSP 核心快捷键（已在 lsp.lua 的 on_attach 中绑定缓冲区局部快捷键，这里仅全局兜底）
map("n", "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<CR>", { desc = "LSP 重命名" })
map("n", "<leader>le", "<cmd>lua vim.diagnostic.open_float()<CR>", { desc = "LSP 诊断浮窗" })
