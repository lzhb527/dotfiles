#!/bin/bash
# 自动配置双远程源脚本
REMOTE_GH="git@github.com:lzhb527/dotfiles.git"
REMOTE_CB="git@codeberg.org:lzhb527/dotfiles.git"


git remote remove origin 2>/dev/null
git remote add origin $REMOTE_GH
git remote set-url --add --push origin $REMOTE_CB
git remote set-url --add --push origin $REMOTE_GH
git remote set-url --add --push origin  lizhengbei@127.0.0.1:lzhb527/dotfiles.git
echo "Remote configured: Push to BOTH, Fetch from GitHub."

# 两个平台设置独立的别名

# 添加独立的 github 别名
git remote add github git@github.com:lzhb527/dotfiles.git

# 添加独立的 codeberg 别名
git remote add codeberg git@codeberg.org:lzhb527/dotfiles.git

# git remote -v ：
# origin: 一键双推（git push origin main）。
# github: 只推/拉 GitHub。
# codeberg: 只推/拉 Codeberg。
为了确保两个平台的 SSH 连接都稳定 ~/.ssh/config 中显式指定密钥（如果不同平台用了不同密钥）：
# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519

# Codeberg
Host codeberg.org
    HostName codeberg.org
    User git
    IdentityFile ~/.ssh/id_ed25519

git push origin main --force
