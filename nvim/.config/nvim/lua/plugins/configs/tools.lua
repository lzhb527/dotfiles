-- FZF 配置
vim.g.fzf_bin_dir = '/opt/homebrew/bin'
vim.env.FZF_DEFAULT_COMMAND = 'fd --type f --hidden --exclude .git --exclude __pycache__ --exclude venv'
vim.env.FZF_DEFAULT_OPTS = '--height 40% --layout=reverse --border rounded --preview "bat --color=always {} --line-range :100"'

vim.g.fzf_colors = {
  fg = {'fg','Normal'}, bg = {'bg','Normal'},
  hl = {'fg','GruvboxOrange'},
  ['fg+'] = {'fg','Normal'}, ['bg+'] = {'bg','GruvboxDarkGray'},
  ['hl+'] = {'fg','GruvboxYellow'}, info = {'fg','GruvboxGray'},
  border = {'fg','GruvboxGray'}, prompt = {'fg','GruvboxBlue'},
  pointer = {'fg','GruvboxRed'}, marker = {'fg','GruvboxGreen'},
  spinner = {'fg','GruvboxPurple'}, header = {'fg','GruvboxGray'},
}

-- ALE 代码检查
vim.g.ale_disable_lsp = 1
vim.g.ale_lsp_auto_configure = 0
vim.g.ale_sign_column_always = 1
vim.g.ale_set_highlights = 0
vim.g.ale_sign_error = '✗'
vim.g.ale_sign_warning = '⚡'
vim.g.ale_linters = { python={'flake8'}, sh={'shellcheck'}, cpp={'clangtidy'} }
vim.g.ale_fixers = { python={'autopep8','yapf'} }

-- Tagbar 代码标签
vim.g.tagbar_width = 30
vim.g.tagbar_autoclose = 1
vim.g.tagbar_auto_preview = 0
vim.g.tagbar_sort = 0
vim.g.tagbar_ctags_bin = 'ctags'
vim.g.tagbar_auto_update = 1
