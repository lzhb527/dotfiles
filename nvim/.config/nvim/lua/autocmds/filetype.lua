local api = vim.api

-- Python 文件缩进设置
api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
    vim.opt_local.autoindent = true
    vim.opt_local.smartindent = true
  end,
})

-- 自动添加文件头
local function auto_set_file_head()
  local buf = api.nvim_get_current_buf()
  local filetype = vim.bo[buf].filetype
  local filename = vim.fn.expand("%:t")
  local year = os.date("%Y")
  local date = os.date("%Y-%m-%d")
  local datetime = os.date("%Y-%m-%d %H:%M:%S")

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

  api.nvim_win_set_cursor(0, {6, 14})
end

api.nvim_create_autocmd("BufNewFile", {
  pattern = {"*.sh", "*.py"},
  callback = auto_set_file_head,
  desc = "Auto add file header for sh/python files"
})

-- Python FZF 预览设置
api.nvim_create_autocmd('FileType',{
  pattern='python',
  callback=function()
    vim.g.fzf_preview_window = {'right:50%','ctrl-/'}
  end
})

-- 恢复上次编辑位置
api.nvim_create_autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    local mark = api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= api.nvim_buf_line_count(0) then
      api.nvim_win_set_cursor(0, mark)
    end
  end
})
