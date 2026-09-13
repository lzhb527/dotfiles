#!/bin/bash
# Filename：notification.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-14
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.
#!/bin/sh

# 1. 安全获取未读通知数（处理所有潜在报错与空值）
COUNT=$(makoctl list -j 2>/dev/null | jq 'length' 2>/dev/null)
: "${COUNT:=0}"

# 2. 区分状态输出精准的 JSON 结构，供 Waybar 自定义模块解析
if [ "$COUNT" -eq 0 ]; then
    jq -n -c \
        --arg text "" \
        --arg alt "none" \
        --arg class "none" \
        --arg tooltip "没有未读通知" \
        '{$text, $alt, $class, $tooltip}'
else
    jq -n -c \
        --arg text "󱅫$COUNT" \
        --arg alt "has-notifications" \
        --arg class "has-notifications" \
        --arg tooltip "当前有 $COUNT 条未读通知" \
        '{$text, $alt, $class, $tooltip}'
fi

