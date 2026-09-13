#!/bin/bash
# Filename：mako-history-wofi.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-14
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.
#!/usr/bin/env bash


#!/usr/bin/env bash

# 1. 获取 Mako 历史，利用 jq 显式按 id 排序
# sort_by(.id) 为升序，加上 reverse 变为降序（最新收到的通知排在 wofi 最顶端）
FORMATTED_LIST=$(makoctl history -j | jq -r 'sort_by(.id) | reverse | .[] | "\(.id): [\(.app_name)] \(.summary) - \(.body)"')

# 检查历史是否为空
if [ -z "$FORMATTED_LIST" ]; then
    echo "当前没有历史通知" | wofi --dmenu --p "历史通知" --width 400 --height 150 --cache-file /dev/null
    exit 0
fi

# 2. 将排序后的列表送入 wofi 菜单
CHOICE=$(echo "$FORMATTED_LIST" | wofi --dmenu --p "历史通知" --width 600 --height 400 --cache-file /dev/null)

# 3. 如果用户在 wofi 中选中了某条历史，则提取其信息并在屏幕上重新弹窗复现
if [ -n "$CHOICE" ]; then
    # 提取被选中通知的原始 ID
    NOTIF_ID=$(echo "$CHOICE" | cut -d':' -f1)
    
    # 依据 ID 精准提取原通知的各项属性
    SUMMARY=$(makoctl history -j | jq -r ".[] | select(.id==$NOTIF_ID) | .summary")
    BODY=$(makoctl history -j | jq -r ".[] | select(.id==$NOTIF_ID) | .body")
    APP=$(makoctl history -j | jq -r ".[] | select(.id==$NOTIF_ID) | .app_name")
    
    # 重新在屏幕上弹窗显示此历史记录
    notify-send -a "$APP" "$SUMMARY" "$BODY"
fi

