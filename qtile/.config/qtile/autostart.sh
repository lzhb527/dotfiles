#!/bin/bash
# Filename：autostart.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-01
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.
#!/bin/bash
# 恢复上次的壁纸
sh ~/.fehbg &
# 这里还可以放其他启动项，比如 picom, nm-applet 等
xrandr --output Virtual-1 --mode 1440x900 --rate 60
