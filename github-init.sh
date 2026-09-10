#!/bin/bash
# 多源同步：fetch 走 GitHub，push 依次发往 Codeberg / GitHub / 本地 Gitea
set -euo pipefail

REMOTE_GH="git@github.com:lzhb527/dotfiles.git"
REMOTE_CB="git@codeberg.org:lzhb527/dotfiles.git"
REMOTE_LOCAL="lizhengbei@127.0.0.1:lzhb527/dotfiles.git"

[ -d .git ] || { echo "错误：请在 git 仓库内运行" >&2; exit 1; }

echo "→ 预检三个源（仅验证连接与仓库存在）..."
git ls-remote "$REMOTE_GH"    >/dev/null 2>&1 || { echo "✗ 无法访问 GitHub"  >&2; exit 1; }
git ls-remote "$REMOTE_CB"    >/dev/null 2>&1 || { echo "✗ 无法访问 Codeberg" >&2; exit 1; }
git ls-remote "$REMOTE_LOCAL" >/dev/null 2>&1 || { echo "✗ 无法访问本地 Gitea" >&2; exit 1; }

git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE_GH"
git remote set-url --add --push origin "$REMOTE_CB"
git remote set-url --add --push origin "$REMOTE_GH"
git remote set-url --add --push origin "$REMOTE_LOCAL"

echo "✓ 配置完成：fetch=GitHub；push=Codeberg → GitHub → 本地 Gitea"
git remote -v
