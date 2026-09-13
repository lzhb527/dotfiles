#!/bin/bash
# Filename：media-toggle.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-25
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.

# 查找真正的 Python 脚本进程（排除当前运行的 grep 进程本身）
PID=$(ps aux | grep 'media-controller.py' | grep -v 'grep' | awk '{print $2}')

if [ -n "$PID" ]; then
    # 如果进程存在，则杀掉它
    kill $PID
else
    # 如果进程不存在，则启动它
    python3 /home/lee/.config/waybar/scripts/media-controller.py &
fi

