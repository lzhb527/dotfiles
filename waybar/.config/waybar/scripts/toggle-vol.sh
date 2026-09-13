#!/bin/bash
# Filename：media-toggle.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-25
# Description：专为 Wayland 优化的音量条一键唤醒/关闭切换脚本
# Copyright (C) 2026  Ltd. All rights reserved.

# 1. 使用 pgrep -f 精准匹配正在运行的脚本完整路径（比 ps aux | grep 更安全高效）
# 同时排除当前的控制脚本自身
PID=$(pgrep -f "bash .*/vol.sh" | head -n 1)

if [ -n "$PID" ]; then
    # 2. 【核心修复】：必须发送 SIGINT (信号2) 或 SIGTERM (信号15)
    # 这样才能触发 vol.sh 内部的 trap 'cleanup' 机制，从而干净地卸载 YAD 和命名管道
    kill -2 "$PID"
else
    # 3. 如果进程不存在，则在后台启动它
    bash /home/lee/.config/waybar/scripts/vol.sh &
fi
