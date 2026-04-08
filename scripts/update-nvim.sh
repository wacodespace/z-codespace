#!/usr/bin/env bash
# z-codespace/scripts/update-nvim.sh — 更新 LazyVim 插件
# ============================================================
# 用法:
#   bash scripts/update-nvim.sh            # 按 lazy-lock.json 同步（幂等）
#   bash scripts/update-nvim.sh --upgrade  # 升级所有插件到最新版本
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PROJECT_ROOT="$(get_project_root)"
UPGRADE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --upgrade) UPGRADE=true; shift ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo "  --upgrade  升级所有插件到最新版本（而非仅同步锁文件）"
            echo "  -h         显示帮助"
            exit 0
            ;;
        *) log_error "未知参数: $1"; exit 1 ;;
    esac
done

main() {
    if ! has_cmd nvim; then
        log_error "未找到 nvim"
        exit 1
    fi

    if [ "$UPGRADE" = "true" ]; then
        log_step "升级所有插件到最新版本..."
        log_warn "升级后请在 nvim 中确认功能正常，然后提交 lazy-lock.json"
        nvim --headless "+Lazy! update" +qa 2>&1
        log_ok "插件升级完成。"
        echo ""
        log_info "下一步:"
        log_info "  1. 运行 nvim 验证功能正常"
        log_info "  2. git add configs/nvim/lazy-lock.json"
        log_info "  3. git commit -m 'chore: update lazy-lock.json'"
    else
        log_step "按 lazy-lock.json 同步插件..."
        nvim --headless "+Lazy! sync" +qa 2>&1
        log_ok "插件同步完成。"
    fi

    echo ""
    log_info "回滚方法:"
    log_info "  git checkout configs/nvim/lazy-lock.json"
    log_info "  bash scripts/update-nvim.sh"
}

main "$@"
