#!/bin/bash
# Filename：wofi-combi.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-15
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.
#!/bin/sh

# 1. 提取系统和用户的桌面应用名称 (drun 的内容)
# 解析 .desktop 文件中的 Name 和 Exec 字段
apps=$(grep -h '^Name=' /usr/share/applications/*.desktop ~/.local/share/applications/*.desktop 2>/dev/null | \
       cut -d'=' -f2 | sort -u | sed 's/^/[应用] /')

# 2. 使用 fd 搜索家目录下的普通文件（排除隐藏文件和常见缓存目录）
# 限制深度或数量可以大幅提高加载速度，这里限制最多展示前 1000 个文件
files=$(fd --type f --hidden --exclude .git --exclude .cache . "$HOME" | head -n 1000 | sed 's/^/[文件] /')

# 3. 将两者合并合并，通过管道喂给 wofi --dmenu
# wofi 会返回你最终回车选择的那一行文字
selected=$(printf "%s\n%s" "$apps" "$files" | wofi --dmenu --prompt "搜索应用或文件...")

# 如果用户直接按了 ESC 没选择，则退出
[ -z "$selected" ] && exit 0

# 4. 判断用户选中的是应用还是文件，并执行对应操作
if echo "$selected" | grep -q "^\[应用\]"; then
    # 如果是应用，提取名称去定位 desktop 文件并执行
    app_name=$(echo "$selected" | sed 's/^\[应用\] //')
    # 找到对应的桌面文件并提取 Exec 命令后台运行
    exec_cmd=$(grep -lh "Name=$app_name" /usr/share/applications/*.desktop ~/.local/share/applications/*.desktop 2>/dev/null | head -n 1 | xargs grep '^Exec=' | cut -d'=' -f2- | sed 's/%[fFuU]//g')
    eval "$exec_cmd" &
elif echo "$selected" | grep -q "^\[文件\]"; then
    # 如果是文件，提取出绝对路径，利用 xdg-open 调用默认程序打开
    file_path=$(echo "$selected" | sed 's/^\[文件\] //')
    xdg-open "$file_path" &
fi

