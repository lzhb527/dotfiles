-- LSP on_attach 函数（逻辑不变，保留原有功能）
local on_attach = function(client, bufnr)
  -- 禁用格式化
  if client.server_capabilities.documentFormattingProvider then
    client.server_capabilities.documentFormattingProvider = false
  end

  -- LSP 快捷键（缓冲区局部绑定）
  local opts = { buffer = bufnr, silent = true, noremap = true }
  vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
  vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
  vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
  vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
  vim.keymap.set("n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
  vim.keymap.set("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
end

-- ====================== 新规范：使用 vim.lsp.config 配置 Pyright ======================
-- 1. 定义 Pyright 的配置（符合 Neovim 0.11+ 新规范）
vim.lsp.config("pyright", {
  on_attach = on_attach,  -- 绑定 on_attach 函数
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true,
      },
    },
  },
  -- 可选：指定 pyright 命令路径（如果系统找不到 pyright-langserver）
  cmd = { "pyright-langserver", "--stdio" },
})

-- 2. 启用 Pyright LSP（替代旧的 require('lspconfig').pyright.setup()）
vim.lsp.enable("pyright")

-- ====================== venv-selector 虚拟环境配置（逻辑不变） ======================
require("venv-selector").setup({
  auto_refresh = true,
  search_workspace = true,
  search_venv_managers = true,
  name = { "venv", ".venv", "env" },
  auto_select = true,
})

-- 自动加载虚拟环境（逻辑不变）
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.cmd("silent! VenvSelectCached")
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    if vim.bo.filetype == "python" then
      vim.cmd("silent! VenvSelectCached")
    end
  end,
})
