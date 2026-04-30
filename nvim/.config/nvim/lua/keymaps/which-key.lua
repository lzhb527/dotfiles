local ok, wk = pcall(require, "which-key")
if not ok then return end

-- which-key 核心配置
wk.setup({
  win = {
    border = "rounded",
  },
})

-- 普通模式快捷键分组
wk.add({
  { "<space>", group = "Main Menu" },

  -- 1. 文件/搜索
  { "<space>f", group = "Find / Search" },
  { "<space>ff", "<cmd>Files<CR>",   desc = "查找文件" },
  { "<space>fg", "<cmd>Rg<CR>",      desc = "全文搜索 (Ripgrep)" },
  { "<space>fb", "<cmd>Buffers<CR>", desc = "查找缓冲区" },
  { "<space>fh", "<cmd>History<CR>", desc = "历史文件" },
  { "<space>fc", "<cmd>Commits<CR>", desc = "Git 提交记录" },
  { "<space>fr", "<cmd>Rg <C-R><C-W><CR>", desc = "搜索光标单词" },

  -- 2. LSP
  { "<space>l", group = "LSP" },
  { "<space>lr", "<cmd>lua vim.lsp.buf.rename()<CR>", desc = "重命名符号" },
  { "<space>le", "<cmd>lua vim.diagnostic.open_float()<CR>", desc = "诊断浮窗" },
  { "<space>lgd", "<cmd>lua vim.lsp.buf.definition()<CR>", desc = "跳转定义" },
  { "<space>lgi", "<cmd>lua vim.lsp.buf.implementation()<CR>", desc = "跳转实现" },
  { "<space>lgr", "<cmd>lua vim.lsp.buf.references()<CR>", desc = "查找引用" },
  { "<space>lK", "<cmd>lua vim.lsp.buf.hover()<CR>", desc = "悬浮文档" },
  { "<space>l[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", desc = "上一个诊断" },
  { "<space>l]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", desc = "下一个诊断" },

  -- 3. 终端
  { "<space>t", group = "Terminal (Floaterm)" },
  { "<space>tn", "<cmd>FloatermNew<CR>", desc = "新建浮动终端" },
  { "<space>tt", "<cmd>FloatermToggle<CR>", desc = "显示/隐藏终端" },
  { "<space>tnx", "<cmd>FloatermNext<CR>", desc = "下一个终端" },
  { "<space>tk", "<cmd>FloatermKill<CR>", desc = "关闭当前终端" },
  { "<space>tf8", desc = "F8 = 新建终端" },
  { "<space>tf9", desc = "F9 = 切换终端" },
  { "<space>tf10", desc = "F10 = 下一个终端" },
  { "<space>tf11", desc = "F11 = 关闭终端" },

  -- 4. Git
  { "<space>g", group = "Git" },
  { "<space>gs", "<cmd>Git<CR>", desc = "Git Status" },
  { "<space>gc", "<cmd>Git commit<CR>", desc = "Git Commit" },
  { "<space>gp", "<cmd>Git push<CR>", desc = "Git Push" },
  { "<space>gl", "<cmd>Git log<CR>", desc = "Git Log" },

  -- 5. 注释
  { "<space>c", group = "Comment" },
  { "<space>cc", "<Plug>NERDCommenterComment", desc = "注释代码" },
  { "<space>cv", "<Plug>NERDCommenterUncomment", desc = "取消注释" },

  -- 6. ALE
  { "<space>a", group = "ALE (Code Check)" },
  { "<space>as", "<cmd>ALEToggle<CR>", desc = "开关 ALE" },
  { "<space>ad", "<cmd>ALEDetail<CR>", desc = "错误详情" },
  { "<space>asp", "<Plug>(ale_previous_wrap)", desc = "上一个错误" },
  { "<space>asn", "<Plug>(ale_next_wrap)", desc = "下一个错误" },

  -- 7. 缓冲区
  { "<space>b", group = "Buffer" },
  { "<space>bd", "<cmd>bdelete!<CR>", desc = "关闭当前缓冲区" },
  { "<space>bn", "<Cmd>BufferLineCycleNext<CR>", desc = "下一个缓冲区" },
  { "<space>bp", "<Cmd>BufferLineCyclePrev<CR>", desc = "上一个缓冲区" },
  { "<space>btab", desc = "Ctrl+Tab = 下一个缓冲区" },
  { "<space>btabp", desc = "Ctrl+Shift+Tab = 上一个缓冲区" },

  -- 8. 窗口
  { "<space>w", group = "Window" },
  { "<space>wv", "<C-w>v", desc = "垂直分屏" },
  { "<space>wh", "<cmd>split<CR>", desc = "水平分屏" },
  { "<space>wc", "<C-w>c", desc = "关闭窗口" },
  { "<space>wo", "<C-w>o", desc = "只保留当前窗口" },

  -- 9. UI/工具
  { "<space>u", group = "UI / Tools" },
  { "<space>uf1", "<cmd>set nu! rnu!<CR>", desc = "F1 = 切换行号显示" },
  { "<space>un", "<cmd>NERDTreeToggle<CR>", desc = "Ctrl+N = NERDTree 切换" },
  { "<space>uf12", "<cmd>TagbarToggle<CR>", desc = "F12 = Tagbar 切换" },
  { "<space>ue", "<Plug>(easymotion-sn)", desc = "/ = Easymotion 搜索跳转" },

  -- 10. 配置/系统
  { "<space>o", group = "Options / System" },
  { "<space>oc", "edit ~/.config/nvim/init.lua", desc = "编辑Neovim配置" },
  { "<space>ou", "<cmd>Lazy update<CR>", desc = "更新插件" },
  { "<space>oq", "<cmd>qa<CR>", desc = "退出所有窗口" },

  -- 11. 保存相关
  { '<space>s', group = 'save', desc = '+保存相关' },
  { '<space>ss', "<cmd>:w<CR>", desc = '保存当前文件' },
  { '<space>sS', "<cmd>:w!<CR>", desc = '强制保存当前文件' },
  { '<space>sw', "<cmd>:w ", desc = '另存为指定文件' },
  { '<space>sa', "<cmd>:wa<CR>", desc = '保存所有文件' },
  { '<space>sq', "<cmd>:q<CR>", desc = '退出当前文件' },

  -- 12. 提示
  { "<space>hint", group = "Shortcut Hints" },
  { "<space>hintf8", desc = "F8 = 新建终端 (<space>tn)" },
  { "<space>hintf9", desc = "F9 = 切换终端 (<space>tt)" },
  { "<space>hintf10", desc = "F10 = 下一个终端 (<space>tnx)" },
  { "<space>hintf11", desc = "F11 = 关闭终端 (<space>tk)" },
  { "<space>hintf1", desc = "F1 = 切换行号 (<space>uf1)" },
  { "<space>hintf12", desc = "F12 = Tagbar切换 (<space>uf12)" },
  { "<space>hintcn", desc = "Ctrl+N = NERDTree切换 (<space>un)" },
  { "<space>hinttab", desc = "Ctrl+Tab = 下一个缓冲区 (<space>bn)" },
  { "<space>hint/", desc = "/ = Easymotion跳转 (<space>ue)" },
}, { mode = "n" })

-- 可视模式
wk.add({
  { "<space>", group = "Main Menu (Visual)" },
  { "<space>c", group = "Comment" },
  { "<space>cc", "<Plug>NERDCommenterComment", desc = "注释选中代码" },
  { "<space>cv", "<Plug>NERDCommenterUncomment", desc = "取消选中注释" },
  { "<space>ue", "<Plug>(easymotion-sn)", desc = "/ = Easymotion 搜索跳转" },
}, { mode = "v" })

-- 终端模式
wk.add({
  { "<space>", group = "Main Menu (Terminal)" },
  { "<space>t", group = "Terminal (Floaterm)" },
  { "<space>tn", "<C-\\><C-n><cmd>FloatermNew<CR>", desc = "新建浮动终端" },
  { "<space>tt", "<C-\\><C-n><cmd>FloatermToggle<CR>", desc = "显示/隐藏终端" },
  { "<space>tnx", "<C-\\><C-n><cmd>FloatermNext<CR>", desc = "下一个终端" },
  { "<space>tk", "<C-\\><C-n><cmd>FloatermKill<CR>", desc = "关闭当前终端" },
}, { mode = "t" })
