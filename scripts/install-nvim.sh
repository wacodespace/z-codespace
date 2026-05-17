#!/usr/bin/env bash
# z-codespace/scripts/install-nvim.sh — 部署 LazyVim 配置
# ============================================================
# 用法:
#   bash scripts/install-nvim.sh           # 部署配置并初始化
#   bash scripts/install-nvim.sh --force   # 强制覆盖不备份
#   bash scripts/install-nvim.sh --no-sync # 仅链接配置，不运行插件同步
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PROJECT_ROOT="$(get_project_root)"
OS="$(detect_os)"

NVIM_CONFIG_SRC="$PROJECT_ROOT/configs/nvim"
NVIM_CONFIG_DST="$HOME/.config/nvim"
NVIM_MIN_VERSION="0.11.2"

FORCE=false
NO_SYNC=false

# --- 参数解析 ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)   FORCE=true; shift ;;
        --no-sync) NO_SYNC=true; shift ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo "  --force     强制覆盖，不备份"
            echo "  --no-sync   仅链接配置，不运行插件同步"
            echo "  -h, --help  显示帮助"
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            exit 1
            ;;
    esac
done

# ============================================================
# 主流程
# ============================================================
main() {
    log_step "=========================================="
    log_step "部署 LazyVim 配置"
    log_step "=========================================="
    echo ""

    # 1. 检查 neovim
    if ! has_cmd nvim; then
        log_error "未找到 nvim。请先运行:"
        log_error "  bash scripts/install-deps.sh"
        exit 1
    fi
    if ! check_nvim_version "$NVIM_MIN_VERSION"; then
        log_error "当前 nvim 版本过低: $(nvim --version | head -n1)"
        log_error "需要 >= ${NVIM_MIN_VERSION}。请先运行:"
        log_error "  bash scripts/install-deps.sh"
        log_error "若已安装到 ~/.local/bin，请确认 PATH 包含: $HOME/.local/bin"
        exit 1
    fi
    log_ok "Neovim: $(nvim --version | head -n1)"

    # 2. 检查关键运行时依赖
    local missing=()
    for cmd in git rg; do
        if ! has_cmd "$cmd"; then
            missing+=("$cmd")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        log_warn "缺少推荐依赖: ${missing[*]}"
        log_warn "部分功能可能不可用，建议先运行: bash scripts/install-deps.sh"
    fi

    # 3. 检查 C 编译器（treesitter 需要）
    if ! has_cmd gcc && ! has_cmd clang; then
        log_warn "缺少 C 编译器 (gcc/clang)，Treesitter parser 将无法编译"
    fi

    # 4. 备份并链接配置
    if [ -e "$NVIM_CONFIG_DST" ] || [ -L "$NVIM_CONFIG_DST" ]; then
        if [ "$FORCE" = "true" ]; then
            log_warn "强制模式: 移除现有配置 $NVIM_CONFIG_DST"
            rm -rf "$NVIM_CONFIG_DST"
        else
            backup_path "$NVIM_CONFIG_DST"
        fi
    fi

    safe_link "$NVIM_CONFIG_SRC" "$NVIM_CONFIG_DST" "true"

    # 5. headless 自检（无需打开交互式 nvim）
    log_step "验证 Neovim 可启动（headless）..."
    if nvim --headless -c "lua print('Neovim 启动成功！')" -c "qa"; then
        log_ok "Neovim headless 启动正常"
    else
        log_error "Neovim 无法在 headless 下完成启动，请检查 ~/.config/nvim"
        exit 1
    fi

    # 6. 初始化 LazyVim
    if [ "$NO_SYNC" = "true" ]; then
        log_info "跳过插件同步 (--no-sync)"
    else
        log_step "初始化 LazyVim（首次运行会安装插件，需要网络）..."
        log_info "运行: nvim --headless '+Lazy! sync' +qa"
        if nvim --headless "+Lazy! sync" +qa 2>&1; then
            log_ok "LazyVim 插件同步完成"
        else
            log_warn "插件同步可能未完全成功，请手动运行 nvim 检查"
        fi
    fi

    # 7. 输出使用说明
    echo ""
    log_ok "=========================================="
    log_ok "LazyVim 配置部署完成！"
    log_ok "=========================================="
    echo ""
    log_info "使用方式:"
    log_info "  nvim              — 启动编辑器"
    log_info "  nvim file.py      — 编辑文件"
    echo ""
    log_info "常用快捷键 (Leader = Space):"
    log_info "  <Space>ff         — 查找文件"
    log_info "  <Space>fg         — 全局搜索 (ripgrep)"
    log_info "  <Space>e          — 文件浏览器"
    log_info "  <Space>l          — Lazy 插件管理"
    log_info "  <C-\\>            — 浮动终端"
    echo ""
    log_info "AI CLI 上下文 (Visual 选中后):"
    log_info "  <Space>xs         — 复制「绝对路径 + 选中代码」到剪贴板"
    log_info "  终端里用 cc / cx 启动 Claude Code / Codex 后粘贴即可"
    echo ""
    log_info "健康检查:"
    log_info "  bash scripts/doctor.sh"
    log_info "  nvim 内运行 :checkhealth"
}

main "$@"
