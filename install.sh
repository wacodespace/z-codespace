#!/bin/bash
# dotfiles 一键安装/卸载脚本
# 用法: 
#   安装: bash install.sh [--force]
#   卸载: bash install.sh --uninstall
#   预览: bash install.sh --dry-run
# ============================================================

set -e

# --- 参数解析 ---
FORCE=false
UNINSTALL=false
DRY_RUN=false
DOTFILES_DIR="$(dirname "$(readlink -f "$0")")"

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "用法: $0 [--force] [--uninstall] [--dry-run]"
            echo "  --force     : 强制覆盖，不备份"
            echo "  --uninstall : 卸载，恢复备份"
            echo "  --dry-run   : 预览模式，不实际执行"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

# --- 颜色输出 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[信息]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[警告]${NC} $1"; }
log_error() { echo -e "${RED}[错误]${NC} $1"; }

# --- 执行包装器 ---
run() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[预览] $*"
    else
        "$@"
    fi
}

# --- 备份函数 ---
backup_item() {
    local target="$1"
    if [[ -e "$target" && ! -L "$target" ]]; then
        local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
        log_warn "备份 $target -> $backup"
        run cp -r "$target" "$backup"
    fi
}

# --- 创建符号链接 ---
link_file() {
    local src="$1"
    local dst="$2"
    
    if [[ "$FORCE" != "true" ]]; then
        backup_item "$dst"
    fi
    
    log_info "链接 $src -> $dst"
    run ln -sf "$src" "$dst"
}

# --- 恢复备份 ---
restore_backup() {
    local target="$1"
    local backup_pattern="${target}.bak.*"
    
    for backup in $backup_pattern; do
        if [[ -e "$backup" ]]; then
            log_info "恢复 $backup -> $target"
            run rm -rf "$target"
            run mv "$backup" "$target"
            return 0
        fi
    done
    log_warn "未找到 $target 的备份文件"
}

# --- 检查 Git 配置 ---
setup_git_config() {
    local url_rule="url.git@github.com:.insteadOf"
    if ! git config --global --get "$url_rule" >/dev/null 2>&1; then
        log_info "设置 Git HTTPS -> SSH 重写规则"
        run git config --global "$url_rule" "https://github.com/"
    else
        log_info "Git HTTPS -> SSH 规则已存在，跳过"
    fi
}

# --- 主函数 ---
main() {
    echo "=== dotfiles 管理脚本 ==="
    echo "源目录: $DOTFILES_DIR"
    echo "模式: ${UNINSTALL:+卸载}${DRY_RUN:+预览}${FORCE:+强制覆盖}"
    echo ""
    
    if [[ "$UNINSTALL" == "true" ]]; then
        # --- 卸载模式 ---
        log_info "开始卸载..."
        restore_backup "$HOME/.bashrc"
        restore_backup "$HOME/.tmux.conf"
        restore_backup "$HOME/.vimrc"
        log_info "卸载完成！请重新打开终端使配置生效。"
    else
        # --- 安装模式 ---
        log_info "开始安装..."
        link_file "$DOTFILES_DIR/.bashrc"    "$HOME/.bashrc"
        link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
        link_file "$DOTFILES_DIR/.vimrc"     "$HOME/.vimrc"
        
        setup_git_config
        
        echo ""
        log_info "安装完成！"
        if [[ "$DRY_RUN" != "true" ]]; then
            echo "请执行 'source ~/.bashrc' 或重新打开终端使配置生效。"
        fi
    fi
}

main "$@"
