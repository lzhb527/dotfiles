#!/bin/bash
# Filename：launch-rofi.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-15
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.

#!/bin/sh

# 1. 尝试杀掉已经存在的实例
if pkill -f "rofi -show drun"; then
    exit 0
fi

# 2. 如果没开，则拉起带自定义脚本和主题的 rofi
# 注意：脚本中可以直接使用标准波浪号 ~
rofi -show drun \
     -modes "drun,File:~/.config/rofi/rofi-fd.sh" \
     -show-icons \
     -theme "~/.config/rofi/con.rasi" \

