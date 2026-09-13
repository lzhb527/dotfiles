#!/bin/bash
# Filename：la.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-15
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.
fd --type f --hidden --exclude .git . "$HOME" | fuzzel -d | xargs -r xdg-open
