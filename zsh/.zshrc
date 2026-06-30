# ==============================================================================
# 1. 性能分析（可选调试用）
# ==============================================================================
# zmodload zsh/zprof

# ==============================================================================
# 2. 插件外观微调
# ==============================================================================
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#888888,underline"

# ==============================================================================
# 3. Python 虚拟环境
# ==============================================================================
source ~/.venv.3.11/bin/activate

# ==============================================================================
# 4. 环境变量与路径配置
# ==============================================================================
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH="/Users/lizhengbei/.local/bin:$PATH"
export PATH="/usr/local/bin:$PATH"

export LANG=en_US.UTF-8
export TERM="xterm-256color"

NVM_DIR="$HOME/.nvm"

# ==============================================================================
# 5. Homebrew 加速与优化（macOS）
# ==============================================================================
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
export HOMEBREW_NO_AUTO_UPDATE=1

if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ==============================================================================
# 6. Zinit 插件管理器安装与加载
# ==============================================================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# ==============================================================================
# 7. 主题与核心插件
# ==============================================================================
zinit ice depth=1

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light zdharma-continuum/history-search-multi-word

# ==============================================================================
# 8. Oh-My-Zsh 片段（功能插件）
# ==============================================================================
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# ==============================================================================
# 9. 补全系统初始化与样式
# ==============================================================================
autoload -Uz compinit && compinit
zinit cdreplay -q

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format ''

zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# ==============================================================================
# 10. 键盘快捷键绑定
# ==============================================================================
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# ==============================================================================
# 11. 历史记录优化
# ==============================================================================
HISTSIZE=50000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# ==============================================================================
# 12. 常用别名
# ==============================================================================
alias c='clear'
alias vim='nvim'
alias o='open'
alias icat='kitty +kitten icat'
alias cat='bat --paging=never --plain'
alias ls='eza --icons=always --color=always'
alias ll='eza -l --time-style=relative'
alias updatedb='/usr/libexec/locate.updatedb'
alias yt-dlpm='/Users/lizhengbei/yt-dlp/bin/yt-dlp -x --audio-format mp3  --audio-quality 0 --embed-thumbnail --embed-metadata'

# alias fzf="fzf --layout=reverse --border=bold --border=rounded --margin=20% --preview='cat {}' --pointer='→' --bind='enter:execute(nvim {})+abort'"

alias hitfm='mpv http://sk.cri.cn/887.m3u8'
alias cctv1='mpv https://stream1.freetv.fun/c26bc29b4c23283f729a3b949065d8be4420cd2339ed981b534aa0ac9bcf22dc.ctv'
alias cctv9='mpv https://stream1.freetv.fun/72df79b1a6e2e9f481761c6f925aa275908f41120aea73c241ba767234402730.ctv'

# ==============================================================================
# 13. 外部工具集成（FZF & Zoxide）
# ==============================================================================
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"
# ==============================================================================
# 14. 性能分析输出（调试用）
# ==============================================================================
# time zsh -i -c exit
# zprof
