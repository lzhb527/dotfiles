local api = vim.api

-- =============================================================================
-- 1. Python 文件类型专属缩进规范设置
-- =============================================================================
api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.tabstop = 4        -- 1个Tab占用4个空格
    vim.opt_local.softtabstop = 4    -- 编辑模式下Tab的退格表现
    vim.opt_local.shiftwidth = 4     -- 自动缩进时的空格数
    vim.opt_local.expandtab = true   -- 强制将所有Tab转换为空格
    vim.opt_local.autoindent = true  -- 开启自动缩进
    vim.opt_local.smartindent = true -- 智能分析代码上下文缩进
  end,
})

-- =============================================================================
-- 2. 新建脚本文件时自动化插入标准的作者声明文件头
-- =============================================================================
local function auto_set_file_head()
  local buf = api.nvim_get_current_buf()
  local filetype = vim.bo[buf].filetype
  local filename = vim.fn.expand("%:t")
  local year = os.date("%Y")
  local date = os.date("%Y-%m-%d")
  local datetime = os.date("%Y-%m-%d %H:%M:%S")

  -- Bash 脚本模板
  if filetype == "sh" then
    local lines = {
      "#!/bin/bash",
      "# Filename：" .. filename,
      "# Author：lizhengbei",
      "# Contact：lizhengbei@gmail.com",
      "# Created Time：" .. date,
      "# Description：",
      "# Copyright (C) " .. year .. "  Ltd. All rights reserved."
    }
    api.nvim_buf_set_lines(buf, 0, 0, false, lines)
  end

  -- Python 脚本模板
  if filetype == "python" then
    local lines = {
      "#!/usr/bin/env python3",
      "# -*- coding:utf-8 -*-",
      "# Filename：" .. filename,
      "# Author：lizhengbei",
      "# Contact：lizhengbei@gmail.com",
      "# Created Time：" .. datetime,
      "# Description：",
      "# Copyright (C) " .. year .. "  Ltd. All rights reserved."
    }
    api.nvim_buf_set_lines(buf, 0, 0, false, lines)
  end

  -- 🌟 智能光标定位：写完头部后，自动将光标放置于第 6 行的 Description 后面，直接开始写脚本描述
  api.nvim_win_set_cursor(0, {6, 14})
end

api.nvim_create_autocmd("BufNewFile", {
  pattern = {"*.sh", "*.py"},
  callback = auto_set_file_head,
  desc = "自动为新建的 sh/python 脚本注入标准的全局作者信息文件头"
})

-- =============================================================================
-- 3. 跨越生命周期：自动恢复文件上一次的编辑位置
-- =============================================================================
-- 只要再次用 Neovim 打开曾经编辑过的文件，光标会瞬间跳回到你上一次关闭时的位置
api.nvim_create_autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    local mark = api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= api.nvim_buf_line_count(0) then
      api.nvim_win_set_cursor(0, mark)
    end
  end
})

