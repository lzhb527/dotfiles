# =============================================================================
# 1. 交互式会话专用配置 (极速提升脚本效率)
# =============================================================================
if status is-interactive

    # 彻底关闭开机无用的欢迎语
    set -g fish_greeting ""

    # -------------------------------------------------------------------------
    # 2. 核心现代工具链初始化 (一行命令，彻底托管 cd，完美自适应软链接和相对路径)
    # -------------------------------------------------------------------------
    if type -q zoxide
        zoxide init fish --cmd cd | source
    end

    if type -q starship
        starship init fish | source
    end

    if type -q fzf
        fzf --fish | source
    end

    function fish_user_key_bindings
        # 先清除 fzf 默认的所有旧绑定（避免按键冲突）
        bind \ct ''  # 清除默认的 Ctrl+T (搜文件)
        bind \ec ''  # 清除默认的 Alt+C (改目录)
        bind \cr ''  # 清除默认的 Ctrl+R (历史记录)
        bind \ed ''

        # 再绑定你自己的自定义快捷键
        bind \eh fzf-history-widget  # Alt + H: 搜历史记录
        bind \ef fzf-file-widget     # Alt + F: 搜文件
        bind \ed fzf-cd-widget       # Alt + G: 切换目录
    end

    # -------------------------------------------------------------------------
    # 3. 现代化别名设置 (Aliases)
    # -------------------------------------------------------------------------
    alias c='clear'
    alias vim='nvim'
    alias hx='helix'

    if type -q bat
        alias cat='bat --paging=never --plain'
    end

    if type -q eza
        alias ls='eza --icons --group-directories-first'
        alias ll='eza -lh --icons -o --git --group-directories-first'
        alias lt="eza -T -L 2 --icons -A --group-directories-first"
    end

    alias kt='kitten @ launch --type=tab'
    alias swb='systemctl --user start waybar'

    # -------------------------------------------------------------------------
    # 4. 顶配 FZF 模糊搜索内核交互 (支持彩色代码与行号预览)
    # -------------------------------------------------------------------------
    if type -q fzf
        alias fzf="fzf --layout=reverse --border=rounded --margin=5% --preview='bat --color=always --style=numbers {} 2>/dev/null || cat {} 2>/dev/null || eza --tree --level=2 --icons {} 2>/dev/null' --pointer='→'"
    end

    # -------------------------------------------------------------------------
    # 5. Arch Linux 专属极速包管理
    # -------------------------------------------------------------------------
    alias pacmani='sudo pacman -S'
    alias pacmanr='sudo pacman -Rns'
    alias pacmanu='sudo pacman -Syu'
    alias pacmans='pacman -Ss'

    # -------------------------------------------------------------------------
    # 6. 终极磁盘清理短函数 (采用官方原生 Function 逻辑，彻底终结 $argv 追加报错)
    # -------------------------------------------------------------------------
    function pc --description 'Clean pacman cache, remove download artifacts, and wipe out orphans safely'

        # 1. 清理旧安装包缓存
        sudo pacman -Sc

        # 2. 智能抓取并抹除孤立依赖包
        set orphans (pacman -Qtdq)
        if count $orphans >/dev/null
            sudo pacman -Rns $orphans
        end
    end

end

# =============================================================================
# 7. 脚本保留区 (默认注释)
# =============================================================================
# bash ~/.config/fish/panes
