#!/bin/bash
# Filename：po.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-16
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.

#!/bin/bash

# 获取系统状态
uptime="$(uptime -p | sed -e 's/up //g')"
host=$(hostname)

# 选项定义：图标后加上对应英文，防止分词失败
lock=" Lock"
logout="󰍃 Logout"
reboot=" Reboot"
shutdown=" Shutdown"

yes=" Yes"
no=" No"

# Fuzzel 基础样式参数
FONT="JetBrainsMono Nerd Font:size=22"
BG_COLOR="1e1e2eff"
TEXT_COLOR="cdd6f4ff"
SEL_COLOR="08bdbaff"

# 1. 弹出主菜单（这里只有 4 个选项，-l 参数改为 4）
SELECTION_IDX=$(printf "%s\n%s\n%s\n%s" "$lock" "$logout" "$reboot" "$shutdown" | \
    fuzzel --dmenu \
    --index \
    -l 4 \
    -w 15 \
    -p "⚡ $host | $uptime: " \
    --font="$FONT" \
    --background="$BG_COLOR" \
    --text-color="$TEXT_COLOR" \
    --selection-color="$SEL_COLOR" \
    --line-height=36)

# 如果用户按 Esc 取消，返回为空，则直接退出
[[ -n $SELECTION_IDX ]] || exit 0

# 2. 确认二次菜单函数
confirm_action() {
    local CONFIRM_IDX
    CONFIRM_IDX=$(printf "%s\n%s" "$yes" "$no" | \
        fuzzel --dmenu \
        --index \
        -l 2 \
        -w 10 \
        -p "⚠️ Are you sure? " \
        --font="$FONT" \
        --background="$BG_COLOR" \
        --text-color="$TEXT_COLOR" \
        --selection-color="f38ba8ff" \
        --line-height=30)
    
    # 因为 printf 中 yes 在第一行，所以选中 Yes 时返回的索引是 0
    [[ "$CONFIRM_IDX" == "0" ]] && return 0 || return 1
}

# 3. 动作匹配（严格对应 0, 1, 2, 3 顺序，彻底修复错位和卡死问题）
case "$SELECTION_IDX" in
    0)  # 对应 $lock
        loginctl lock-session
        ;;
    1)  # 对应 $logout
        confirm_action && labwc --exit
        ;;
    2)  # 对应 $reboot
        confirm_action && systemctl reboot
        ;;
    3)  # 对应 $shutdown
        confirm_action && systemctl poweroff
        ;;
esac

