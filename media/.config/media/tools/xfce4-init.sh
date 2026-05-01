#!/bin/bash
# Filename：xfce4-init.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-01
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.

# 设置顶部留白 (33px)
xfconf-query -c xfwm4 -p /general/margin_top -n -t int -s 33

# 设置左侧留白 (8px)
xfconf-query -c xfwm4 -p /general/margin_left -n -t int -s 8

# 设置右侧留白 (8px)
xfconf-query -c xfwm4 -p /general/margin_right -n -t int -s 8

# 设置底部留白 (8px)
xfconf-query -c xfwm4 -p /general/margin_bottom -n -t int -s 8

xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>Return" -n -t string -s "kitty"
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>slash" -n -t string -s "kitten quick-access-terminal"
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>o" -n -t string -s "ulauncher"
# xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>f" -n -t string -s "maximize_window_key"
