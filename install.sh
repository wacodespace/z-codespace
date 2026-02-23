#!/bin/bash
# dotfiles 一键安装脚本
# 用法: git clone <repo> ~/dotfiles && cd ~/dotfiles && bash install.sh
# ============================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== dotfiles 安装脚本 ==="
echo "源目录: $DOTFILES_DIR"
echo ""

# 备份已有配置
backup_file() {
    local target="$1"
    if [ -f "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
        echo "[备份] $target -> $backup"
        cp "$target" "$backup"
    fi
}

# 创建符号链接
link_file() {
    local src="$1"
    local dst="$2"
    backup_file "$dst"
    ln -sf "$src" "$dst"
    echo "[链接] $src -> $dst"
}

# --- 安装配置文件 ---
link_file "$DOTFILES_DIR/.bashrc"    "$HOME/.bashrc"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/.vimrc"     "$HOME/.vimrc"

# --- 应用 Git 全局配置 ---
git config --global url."git@github.com:".insteadOf "https://github.com/"
echo "[Git]  已设置 HTTPS -> SSH 重写规则"

echo ""
echo "=== 安装完成！==="
echo "请执行 'source ~/.bashrc' 或重新打开终端使配置生效。"
