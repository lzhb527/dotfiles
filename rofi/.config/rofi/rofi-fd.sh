#!/bin/bash
# Filename：rofi-fd.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-15
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.

if [ $# -eq 0 ]; then
    # 正常输出列表给 rofi
    fd --type f --hidden --exclude .git --exclude .cache . "$HOME" 
else
    # 【核心修改点】：不要直接用 &，改用以下格式完全脱离 rofi 进程控制
    coproc ( xdg-open "$1" >/dev/null 2>&1 )
    
    # 或者用底层标准的 setsid 独立开启新会话：
    # setsid xdg-open "$1" >/dev/null 2>&1 &
    
    # 显式向 Rofi 传递信号强制其关闭
    exit 0
fi

