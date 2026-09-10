#!/bin/bash
# Filename：install.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-04-13
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.

#!/bin/bash
# 确保在 dotfiles 目录下执行
cd "$(dirname "$0")"

# 遍历所有文件夹（排除隐藏文件夹）并执行 stow
for dir in $(ls -d */ | cut -f1 -d'/'); do
    echo "Stowing $dir..."
    stow -R "$dir" -t "$HOME"
done

echo "Done! 所有配置已同步。"
