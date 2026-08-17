# =============================================================================
# 1. 核心全局配置 (非交互模式也生效，保持轻量)
# =============================================================================
set -g fish_greeting "" # 禁用启动问候语

# 在 Alacritty 会话中声明终端能力为 alacritty
# (其 terminfo 含 Smulx，Neovim 检测到后才会发送下划线颜色 guisp/sp；
#  否则按 xterm-256color 处理，DECRQSS 探测 Alacritty 不应答，下划线颜色丢失)
if set -q ALACRITTY_WINDOW_ID
    if infocmp alacritty >/dev/null 2>&1
        set -gx TERM alacritty
    end
end

# =============================================================================
# 2. 仅在交互模式下运行的配置 (终端日常使用)
# =============================================================================
if status is-interactive

    # --- 1. 环境变量与包管理器初始化 (优先加载) ---
    if test -d /opt/homebrew
        /opt/homebrew/bin/brew shellenv | source
    end

    # 快捷添加 PATH（fish_add_path 会自动去重，无需重复添加）
    fish_add_path ~/.local/bin
    fish_add_path /usr/local/bin
    fish_add_path ~/usr/command-line-tools/bin

    # --- 2. Python 虚拟环境自动激活 ---
    if test -f ~/.venv.3.13/bin/activate.fish
        source ~/.venv.3.13/bin/activate.fish
    end

    # --- 3. 别名设置 (Aliases) ---
    if type -q nvim;   alias vim='nvim'; end
    if type -q bat;    alias cat='bat --paging=never --plain'; end
    if type -q kitty;  alias icat='kitty +kitten icat'; end
    alias c='clear'
    alias kt='kitten @ launch --type tab'

    # Eza 高级文件列表增强
    if type -q eza
        alias ls='eza --icons --group-directories-first'
        alias ll='eza -lh --icons -o --git --group-directories-first'
        alias lt='eza -T -L 2 --icons -A --group-directories-first'
    end

    # --- 4. 现代 CLI 工具初始化 ---
    # Zoxide (智能目录跳转 - 官方原生劫持 cd 模式)
    if type -q zoxide
        zoxide init fish --cmd cd | source
    end

    # Starship (终端提示符 - 定义 fish_prompt, 需在工具初始化之后加载)
    if type -q starship
        starship init fish | source
    end

    if type -q fzf
        fzf --fish | source
    end

    # --- 5. 每次提示符刷新时向终端/tmux 发送当前目录 (OSC 7) ---
    # tmux 收到后即时更新 pane_current_path, 让 automatic-rename 立刻感知 cd (无需降低 status-interval)
    function __update_osc7 --on-event fish_prompt
        printf '\e]7;file://%s%s\e\\' (hostname) (string escape --style=url "$PWD")
    end

    # --- 6. 顶配 FZF 模糊搜索内核交互 (支持彩色代码与行号预览) ---
    if type -q fzf
        alias fzf="fzf --layout=reverse --border=rounded --margin=1% --preview='bat --color=always --style=numbers {} 2>/dev/null || cat {} 2>/dev/null || eza --tree --level=2 --icons {} 2>/dev/null' --pointer='→'"
    end

    # --- 7. 自定义按键绑定 ---
    function fish_user_key_bindings
        # 启用 vi 混合模式（保留 emacs 行编辑，Esc 后可用 f/t 跳转）
        fish_hybrid_key_bindings

        # 先清除 fish 预设绑定, 避免与自定义键冲突 (ctrl-t/cr, alt-c 默认是 transpose/history-pager/capitalize-word)
        bind -M insert \ct ''
        bind -M default \ct ''
        bind -M insert \ec ''
        bind -M default \ec ''
        bind -M insert \cr ''
        bind -M default \cr ''

        # 再绑定你自己的自定义快捷键（两种模式都绑，打字时也能用）
        bind -M insert \eh fzf-history-widget  # Alt + H: 搜历史记录
        bind -M default \eh fzf-history-widget
        bind -M insert \ef fzf-file-widget     # Alt + F: 搜文件
        bind -M default \ef fzf-file-widget
        bind -M insert \ed fzf-cd-widget       # Alt + D: 切换目录
        bind -M default \ed fzf-cd-widget

        # 按编号精确跳转单词 (insert 模式 [打字时] 和 default 模式 [Esc 后])
        bind -M insert \ew fish_easymotion_jump  # Alt+W: 按编号精确跳转单词
        bind -M default \ew fish_easymotion_jump
        bind -M insert \eg fish_easymotion_jump  # Alt+G: 按编号精确跳转单词
        bind -M default \eg fish_easymotion_jump
    end

end

