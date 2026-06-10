#!/bin/bash
# Filename：vol.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-06-07
# Description：基于 PipeWire(wpctl) 与 YAD 的轻量化悬浮音量条（优化版）
# Copyright (C) 2026  Ltd. All rights reserved.

# 1. 精准获取当前默认音频输出的状态
VOLUME_RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)

# 检查是否处于静音状态 (MUTED)
if echo "$VOLUME_RAW" | grep -q "[MUTED]"; then
    CURRENT_VOL=0
else
    # 转换为 0-100 的整数
    CURRENT_VOL=$(echo "$VOLUME_RAW" | awk '{print int($2 * 100)}')
fi

# 如果未获取到数值，默认回退到 50
[ -z "$CURRENT_VOL" ] && CURRENT_VOL=50

# 2. 启动 YAD 实时监听（移除了冲突的 --width，统一在 geometry 中控制）
# 调整 geometry 参数以匹配你的屏幕位置：宽260x高15，距离右侧5px，距离顶部42px
GDK_BACKEND=x11 yad --scale --undecorated --skip-taskbar --no-buttons --close-on-unfocus --on-top \
    --geometry=260x15-5+42 \
    --value="$CURRENT_VOL" --min-value=0 --max-value=100 --step=2 \
    --print-partial | while read -r VOLUME; do

    # 3. 当滑块拖动产生新数值时，实时通过 wpctl 调整系统音量
    if [[ "$VOLUME" =~ ^[0-9]+$ ]]; then
        # 如果用户拖动了音量，自动解除可能存在的静音状态
        wpctl set-mute @DEFAULT_AUDIO_SINK@ 0

        # 将整数转换为 wpctl 所需的两位小数 (0.00 - 1.00)
        TARGET_VOL=$(awk -v vol="$VOLUME" 'BEGIN {printf "%.2f", vol / 100}')
        wpctl set-volume @DEFAULT_AUDIO_SINK@ "$TARGET_VOL"
    fi
done
