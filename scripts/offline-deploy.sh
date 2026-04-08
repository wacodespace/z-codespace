#!/usr/bin/env bash
# z-codespace/scripts/offline-deploy.sh — 在无网机器上部署离线包
# ============================================================
#
# 用法: bash deploy.sh [--force]
#
# 此脚本应从解压后的 nvim-bundle/ 目录中运行:
#   tar xzf nvim-offline-*.tar.gz
#   bash nvim-bundle/deploy.sh
#
# 部署内容:
#   nvim-config  -> ~/.config/nvim       (配置文件)
#   share-nvim   -> ~/.local/share/nvim  (插件 + parsers + mason)
#   state-nvim   -> ~/.local/state/nvim  (lazy state)
# ============================================================

set -euo pipefail

# --- 颜色输出（自包含，不依赖 lib.sh）---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { printf "${GREEN}[INFO]${NC}  %s\n" "$*"; }
log_warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
log_step()  { printf "${BLUE}[STEP]${NC}  %s\n" "$*"; }
log_ok()    { printf "${GREEN}[ OK ]${NC}  %s\n" "$*"; }

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force) FORCE=true; shift ;;
        -h|--help)
            echo "用法: $0 [--force]"
            echo "  --force  强制覆盖已有配置（不备份）"
            exit 0
            ;;
        *) shift ;;
    esac
done

# --- 备份 ---
backup_if_exists() {
    local target="$1"
    if [ "$FORCE" = "true" ]; then
        [ -e "$target" ] && rm -rf "$target"
        return 0
    fi
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
        log_warn "备份: $target -> $backup"
        mv "$target" "$backup"
    elif [ -L "$target" ]; then
        rm -f "$target"
    fi
}

# --- 部署目录 ---
deploy_dir() {
    local src="$1"
    local dst="$2"
    local desc="$3"

    if [ ! -d "$src" ]; then
        log_warn "源目录不存在，跳过: $src"
        return 0
    fi

    log_step "部署${desc}..."
    backup_if_exists "$dst"
    mkdir -p "$(dirname "$dst")"
    cp -r "$src" "$dst"
    log_ok "${desc}已部署到: $dst"
}

main() {
    log_step "=========================================="
    log_step "离线部署 Neovim 环境"
    log_step "=========================================="
    echo ""

    # 检查 bundle 完整性
    if [ ! -d "$BUNDLE_DIR/nvim-config" ]; then
        log_error "未找到 nvim-config/，请确认在 nvim-bundle/ 目录中运行"
        exit 1
    fi

    # 显示包信息
    if [ -f "$BUNDLE_DIR/MANIFEST.txt" ]; then
        log_info "--- 包信息 ---"
        cat "$BUNDLE_DIR/MANIFEST.txt"
        echo ""
    fi

    # 检查 nvim
    if ! command -v nvim >/dev/null 2>&1; then
        log_warn "未找到 nvim 命令，请先安装 Neovim"
        log_warn "可使用 scripts/install-deps.sh 或手动安装"
    fi

    # 部署
    deploy_dir "$BUNDLE_DIR/nvim-config"  "$HOME/.config/nvim"       "nvim 配置"
    deploy_dir "$BUNDLE_DIR/share-nvim"   "$HOME/.local/share/nvim"  "插件数据"
    deploy_dir "$BUNDLE_DIR/state-nvim"   "$HOME/.local/state/nvim"  "状态数据"

    echo ""
    log_ok "=========================================="
    log_ok "离线部署完成！"
    log_ok "=========================================="
    echo ""
    log_info "验证:"
    log_info "  nvim --version          — 检查 Neovim"
    log_info "  nvim +checkhealth       — 运行健康检查"
    echo ""
    log_info "注意:"
    log_info "  - 如果 nvim 不在 PATH 中，请添加: export PATH=\"\$HOME/.local/bin:\$PATH\""
    log_info "  - 首次启动可能需要等待 treesitter 编译（如果 parser 架构不匹配）"
    log_info "  - Mason 工具路径: ~/.local/share/nvim/mason/bin/"
}

main "$@"
