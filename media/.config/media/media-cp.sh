#!/bin/bash
# Filename：media-cp.sh
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-04-14
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.nvim-linux-arm64.appimage
cp 星晴.mp3  ~/Music/
cp def-wallpapers/* ~/Pictures/
cp lishenjin.mp4 ~/Videos/
cp never-say-never.mp3 ~/Music/
tar -xvf ~/.local/share/fonts/jetbrain.tar.xz -C ~/.local/share/fonts/ 2>/dev/null
tar -xvf ~/.local/share/icons/Flat-Remix-Green.tar.xz -C ~/.local/share/icons/ 2>/dev/null
tar -xvf ~/.local/share/themes/Skeuos-Green-Dark.tar.xz -C ~/.local/share/themes/ 2>/dev/null

starship  preset nerd-font-symbols -o ~/.config/starship.toml

cat <<EOF >> ~/.config/starship.toml

[character]
success_symbol = "[❯](red)[❯](yellow)[❯](green)"
error_symbol = "[❯](red)[❯](red)[❯](red)"
EOF
######### nvim ######
aria2c https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-arm64.appimage
chmod +x nvim-linux-arm64.appimage

######### Ulauncher ######
aria2c https://github.com/Ulauncher/Ulauncher/releases/download/5.15.15/ulauncher_5.15.15_all.deb

######## chfs #########
# aria2c http://iscute.cn/tar/chfs/3.1/chfs-linux-arm64-3.1.zip

# unzip chfs-linux-arm64-3.1.zip
# chmod +x chfs-linux-arm64-3.1

######## kitty ########

aria2c https://github.com/kovidgoyal/kitty/releases/download/v0.46.2/kitty-0.46.2-arm64.txz
sudo tar -xvf kitty-0.46.2-arm64.txz -C /opt/

sudo ln -s /usr/bin/fdfind /usr/bin/fd
sudo apt install -f ./ulauncher_5.15.15_all.deb
sudo mv nvim-linux-arm64.appimage /usr/local/bin/nvim
chsh -s /usr/bin/fish
