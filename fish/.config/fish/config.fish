if status is-interactive
# Commands to run in interactive sessions can go here
end

# bash ~/.config/fish/panes

if type -q zoxide
    zoxide init fish | source
end
function cd
    z $argv
end
set -g fish_greeting ""
alias vim='nvim'
alias ls='eza --icons'
alias cat='batcat --paging never --plain'
# alias mpv 'flatpak run io.mpv.Mpv'
alias c='clear'
# 快捷操作 zypper
alias zi='sudo zypper in' 
alias zr='sudo zypper rm -u'    
alias zu='sudo zypper dup --no-allow-vendor-change'
alias zs='zypper se'
alias znoautoref='zypper mr -R -a'
alias zref='sudo zypper ref'
alias fzf="fzf --layout=reverse --border=bold --border=rounded --margin=20% --preview='cat {}' --pointer='→' --bind='enter:execute(nvim {})+abort'"
alias ni='sudo nala install'
alias nr='sudo nala purge'
alias nu='sudo nala update'
alias nug='sudo nala upgrade'

starship init fish | source
