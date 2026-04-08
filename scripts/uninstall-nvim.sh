#!/usr/bin/env bash
# z-codespace/scripts/uninstall-nvim.sh — 卸载 LazyVim 配置
# ============================================================
# 用法:
#   bash scripts/uninstall-nvim.sh         # 仅移除配置链接
#   bash scripts/uninstall-nvim.sh --all   # 同时清理插件和缓存数据
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

CLEAN_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --all) CLEAN_ALL=true; shift ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo "  --all    同时清理插件缓存和状态数据"
            echo "  -h       显示帮助"
            exit 0
            ;;
        *) log_error "未知参数: $1"; exit 1 ;;
    esac
done

main() {
    log_step "卸载 LazyVim 配置..."

    # 移除配置
    local nvim_config="$HOME/.config/nvim"
    if [ -L "$nvim_config" ]; then
        log_info "移除软链接: $nvim_config"
        rm -f "$nvim_config"
        log_ok "配置链接已移除"
    elif [ -d "$nvim_config" ]; then
        backup_path "$nvim_config"
        rm -rf "$nvim_config"
        log_ok "配置目录已移除（已备份）"
    else
        log_info "配置不存在，无需移除"
    fi

    # 清理数据
    if [ "$CLEAN_ALL" = "true" ]; then
        log_step "清理插件和缓存数据..."
        local dirs=(
            "$HOME/.local/share/nvim"
            "$HOME/.local/state/nvim"
            "$HOME/.cache/nvim"
        )
        for d in "${dirs[@]}"; do
            if [ -e "$d" ]; then
                log_info "移除: $d"
                rm -rf "$d"
            fi
        done
        log_ok "插件和缓存数据已清理"
    fi

    echo ""
    log_ok "卸载完成。"
    if [ "$CLEAN_ALL" != "true" ]; then
        log_info "提示: 使用 --all 可同时清理插件缓存:"
        log_info "  ~/.local/share/nvim"
        log_info "  ~/.local/state/nvim"
        log_info "  ~/.cache/nvim"
    fi
}

main "$@"
